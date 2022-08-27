//
//  MainView.swift
//  PlayCover
//

import SwiftUI

enum XcodeInstallStatus {
    case failed, success, installing
}

struct MainView: View {
    @Environment(\.openURL) var openURL
    @EnvironmentObject var install: InstallVM
    @EnvironmentObject var apps: AppsVM
    @EnvironmentObject var store: StoreVM
    @EnvironmentObject var integrity: AppIntegrity

    @Binding public var xcodeCliInstalled: Bool

    @State private var selectedView: Int? = -1
    @State private var navWidth: CGFloat = 0
    @State private var viewWidth: CGFloat = 0
    @State private var collapsed: Bool = false
    @State private var isInstallingXcodeCli = false
    @State private var xcodeInstallStatus: XcodeInstallStatus = .installing

    var body: some View {
        GeometryReader { viewGeom in
            NavigationView {
                GeometryReader { sidebarGeom in
                    List {
                        NavigationLink(destination: AppLibraryView(), tag: 1, selection: self.$selectedView) {
                            Label("sidebar.appLibrary", systemImage: "square.grid.2x2")
                        }
                        NavigationLink(destination: IPALibraryView(), tag: 2, selection: self.$selectedView) {
                            Label("sidebar.ipaLibrary", systemImage: "arrow.down.circle")
                        }
                    }
                    .onChange(of: sidebarGeom.size) { newSize in
                        navWidth = newSize.width
                    }
                }
                .background(SplitViewAccessor(sideCollapsed: $collapsed))
            }
            .onAppear {
                self.selectedView = 1
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: toggleSidebar, label: {
                        Image(systemName: "sidebar.leading")
                    })
                }
            }
            .overlay {
                HStack {
                    if !collapsed {
                        Spacer()
                            .frame(width: navWidth)
                    }
                    ToastView()
                        .environmentObject(ToastVM.shared)
                        .environmentObject(InstallVM.shared)
                        .frame(width: collapsed ? viewWidth : (viewWidth - navWidth))
                        .animation(.spring(), value: collapsed)
                }
            }
            .onChange(of: viewGeom.size) { newSize in
                viewWidth = newSize.width
            }
            .alert("alert.moveAppToApplications.title",
                   isPresented: $integrity.integrityOff) {
                Button("alert.moveAppToApplications.move", role: .cancel) {
                    integrity.moveToApps()
                }
                .tint(.accentColor)
                .keyboardShortcut(.defaultAction)
            } message: {
                Text("alert.moveAppToApplications.subtitle")
            }
            .sheet(isPresented: Binding<Bool>(
                get: {return !xcodeCliInstalled},
                set: {value in xcodeCliInstalled = value})) {
                VStack(spacing: 12) {
                    switch xcodeInstallStatus {
                    case .installing:
                        if !isInstallingXcodeCli {
                            Text("xcode.install.message")
                            .font(.title3)
                            Button("button.Install") {
                                installXcodeCli()
                                isInstallingXcodeCli = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.accentColor)
                            .controlSize(.large)
                        } else {
                            VStack {
                                ProgressView("xcode.install.progress")
                                    .progressViewStyle(.circular)
                                Text("xcode.install.progress.subtext")
                                    .foregroundColor(.secondary)
                            }
                        }
                    case .success:
                        Text("xcode.install.success")
                            .font(.title3)
                        Text("alert.restart")
                            .foregroundColor(.secondary)
                        Button("button.Close") {
                            NSApplication.shared.terminate(nil)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.accentColor)
                        .controlSize(.large)
                    case .failed:
                        Text("xcode.install.failed")
                            .font(.title3)
                        Text("")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(height: 150)
            }
        }
        .frame(minWidth: 675, minHeight: 330)
    }

    func installXcodeCli() {
        if let path = Bundle.main.url(forResource: "xcode_install", withExtension: "scpt") {
            DispatchQueue.global(qos: .userInteractive).async {
                let task = Process()
                let taskOutput = Pipe()
                task.launchPath = "/usr/bin/osascript"
                task.arguments = ["\(path.path)"]
                task.standardOutput = taskOutput
                task.launch()
                task.waitUntilExit()

                DispatchQueue.main.async {
                    let data = taskOutput.fileHandleForReading.readDataToEndOfFile()
                    if let output = String(data: data, encoding: .utf8) {
                        let trimmed = output.filter { !$0.isWhitespace }
                        if trimmed.isEmpty {
                            isInstallingXcodeCli = false
                            xcodeInstallStatus = .success
                        } else {
                            isInstallingXcodeCli = false
                            xcodeInstallStatus = .failed
                        }
                    } else {
                        isInstallingXcodeCli = false
                        Log.shared.error("Failed to interpret console output!")
                    }
                }
            }
        } else {
            isInstallingXcodeCli = false
            xcodeInstallStatus = .failed
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
            var sview = self.superview

            // Find split view through hierarchy
            while sview != nil, !sview!.isKind(of: NSSplitView.self) {
                sview = sview?.superview
            }
            guard let sview = sview as? NSSplitView else { return }

            controller = sview.delegate as? NSSplitViewController

            if let sideBar = controller?.splitViewItems.first {
                observer = sideBar.observe(\.isCollapsed, options: [.new]) { [weak self] _, change in
                    if let value = change.newValue {
                        self?.sideCollapsed?.wrappedValue = value
                    }
                }
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    @State static var xcodeCliInstalled = true

    static var previews: some View {
        MainView(xcodeCliInstalled: $xcodeCliInstalled)
            .environmentObject(InstallVM.shared)
            .environmentObject(AppsVM.shared)
            .environmentObject(StoreVM.shared)
            .environmentObject(AppIntegrity())
    }
}
