//
//  MainView.swift
//  PlayCover
//

import SwiftUI

struct MainView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.controlActiveState) var controlActiveState

    @Environment(AppsVM.self) var apps
    @Environment(StoreVM.self) var store
    @Environment(AppIntegrity.self) var integrity

    @Environment(KeyCoverService.self) private var keyCover

    @Binding public var isSigningSetupShown: Bool

    @State private var selectedView: Int? = -1
    @State private var navWidth: CGFloat = 0
    @State private var viewWidth: CGFloat = 0
    @State private var collapsed: Bool = false
    @State private var showSourceFolders = true
    @State private var selectedBackgroundColor: Color = Color.accentColor
    @State private var selectedTextColor: Color = Color.black

    @Environment(URLObservable.self) private var URLObserved

    var body: some View {
        GeometryReader { viewGeom in
            NavigationSplitView {
                GeometryReader { sidebarGeom in
                    List(selection: $selectedView) {
                        NavigationLink(value: 1) {
                            Label("sidebar.appLibrary", systemImage: "square.grid.2x2")
                        }
                        NavigationLink(value: 2) {
                            HStack {
                                Label("sidebar.ipaLibrary", systemImage: "arrow.down.circle")
                                Button {
                                    withAnimation {
                                        showSourceFolders.toggle()
                                    }
                                } label: {
                                    Image(systemName: showSourceFolders ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        if showSourceFolders {
                            let enabledSources: [SourceJSON] = store.getEnabledSources()
                            ForEach(enabledSources, id: \.hashValue) { source in
                                NavigationLink(value: source.hashValue) {
                                    Label(source.name, systemImage: "folder")
                                        .font(.caption)
                                        .padding(.leading)
                                }
                            }
                        }
                    }
                    .frame(minWidth: 150)
                    .toolbar(removing: .sidebarToggle)
                    .toolbar {
                        ToolbarItem { // Sits on the left by default
                            Button {
                                toggleSidebar()
                            } label: {
                                Image(systemName: "sidebar.leading")
                            }
                        }
                    }
                    .onChange(of: sidebarGeom.size) { _, newSize in
                        navWidth = newSize.width
                    }
                    .onChange(of: colorScheme) { _, scheme in
                        if scheme == .dark {
                            selectedTextColor = .white
                        } else {
                            if controlActiveState == .inactive {
                                selectedTextColor = .black
                            } else {
                                selectedTextColor = .white
                            }
                        }
                    }
                    .onChange(of: controlActiveState) { _, state in
                        if state == .inactive {
                            if colorScheme == .light {
                                selectedTextColor = .black
                            }
                            selectedBackgroundColor = .secondary
                        } else {
                            if colorScheme == .light {
                                selectedTextColor = .white
                            }
                            selectedBackgroundColor = .accentColor
                        }
                    }
                    .onAppear {
                        if colorScheme == .dark {
                            selectedTextColor = .white
                        } else {
                            if controlActiveState == .inactive {
                                selectedTextColor = .black
                            } else {
                                selectedTextColor = .white
                            }
                        }
                    }
                }
                .background(SplitViewAccessor(sideCollapsed: $collapsed))
            } detail: {
                detailView
            }
            .onAppear {
                self.selectedView = URLObserved.type == .source ? 2 : 1
            }
            .toastOverlay {
                HStack {
                    var spacerWidth: CGFloat {
                        // space width changes depending on if it is liquid glass and its accompanying custom padding
                        #if compiler(>=6.2)
                        if #available(macOS 26.0, *) {
                            return navWidth + ToastView.toastGlassPadding
                        }
                        #endif
                        return navWidth
                    }

                    if !collapsed {
                        Spacer()
                            .frame(width: spacerWidth)
                    }
                    ToastView()
                        // add a max statement here to ensure that the width will never be negative
                        .frame(width: max(0, collapsed || viewWidth < navWidth ? viewWidth : (viewWidth - spacerWidth)))
                        .animation(.spring(), value: collapsed)
                }
            }
            .onChange(of: viewGeom.size) { _, newSize in
                viewWidth = newSize.width
            }
            .alert("alert.moveAppToApplications.title",
                   isPresented: Bindable(integrity).integrityOff) {
                Button("alert.moveAppToApplications.move", role: .cancel) {
                    integrity.moveToApps()
                }
                .tint(.accentColor)
                .keyboardShortcut(.defaultAction)
            } message: {
                Text("alert.moveAppToApplications.subtitle")
            }
            .sheet(isPresented: $isSigningSetupShown) {
                SignSetupView(isSigningSetupShown: $isSigningSetupShown)
            }
            .onChange(of: URLObserved.action) {
                self.selectedView = URLObserved.type == .source ? 2 : self.selectedView
            }
            .sheet(isPresented: Binding(get: { keyCover.isUnlockPromptShown },
                                        set: { if !$0 { keyCover.dismissUnlockPrompt() } })) {
                KeyCoverUnlockingPrompt()
            }
        }
        .frame(minWidth: 675, minHeight: 330)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedView {
        case 1:
            AppLibraryView(selectedBackgroundColor: $selectedBackgroundColor,
                           selectedTextColor: $selectedTextColor)
        case 2:
            IPALibraryView(storeVM: store,
                           selectedBackgroundColor: $selectedBackgroundColor,
                           selectedTextColor: $selectedTextColor)
        default:
            if let source = store.getEnabledSources().first(where: { $0.hashValue == selectedView }) {
                IPASourceView(storeVM: store,
                              selectedBackgroundColor: $selectedBackgroundColor,
                              selectedTextColor: $selectedTextColor,
                              sourceName: source.name,
                              sourceApps: source.data)
            }
        }
    }

    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

struct SplitViewAccessor: NSViewRepresentable {
    @Binding var sideCollapsed: Bool

    func makeNSView(context: Context) -> some NSView {
        let view = MyView()
        view.sideCollapsed = _sideCollapsed
        return view
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {}

    class MyView: NSView {
        var sideCollapsed: Binding<Bool>?
        weak private var controller: NSSplitViewController?
        private var observer: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            var sview = superview

            // Find split view through hierarchy
            // swiftlint:disable:next force_unwrapping
            while sview != nil, !sview!.isKind(of: NSSplitView.self) {
                sview = sview?.superview
            }
            guard let sview = sview as? NSSplitView else { return }

            controller = sview.delegate as? NSSplitViewController

            if let sideBar = controller?.splitViewItems.first {
                observer = sideBar.observe(\.isCollapsed, options: [.new]) { [weak self] _, change in
                    guard let value = change.newValue else { return }
                    Task { @MainActor [weak self] in
                        self?.sideCollapsed?.wrappedValue = value
                    }
                }
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    @State static var isSigningSetupShown = true

    static var previews: some View {
        MainView(isSigningSetupShown: $isSigningSetupShown)
            .appEnvironment()
    }
}
