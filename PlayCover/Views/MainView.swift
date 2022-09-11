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
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.controlActiveState) var controlActiveState

    @EnvironmentObject var install: InstallVM
    @EnvironmentObject var apps: AppsVM
    @EnvironmentObject var store: StoreVM
    @EnvironmentObject var integrity: AppIntegrity

    @Binding public var xcodeCliInstalled: Bool
    @Binding public var isSigningSetupShown: Bool

    @State private var selectedView: Int? = -1
    @State private var navWidth: CGFloat = 0
    @State private var viewWidth: CGFloat = 0
    @State private var collapsed: Bool = false
    @State private var isInstallingXcodeCli: Bool = false
    @State private var xcodeInstallStatus: XcodeInstallStatus = .installing
    @State private var selectedBackgroundColor: Color = Color.accentColor
    @State private var selectedTextColor: Color = Color.black
    var body: some View {
        GeometryReader { viewGeom in
            NavigationView {
                GeometryReader { sidebarGeom in
                    List {
                        NavigationLink(destination: AppLibraryView(selectedBackgroundColor: $selectedBackgroundColor,
                                                                   selectedTextColor: $selectedTextColor),
                                       tag: 1, selection: self.$selectedView) {
                            Label("sidebar.appLibrary", systemImage: "square.grid.2x2")
                        }
                        NavigationLink(destination: IPALibraryView(selectedBackgroundColor: $selectedBackgroundColor,
                                                                   selectedTextColor: $selectedTextColor),
                                       tag: 2, selection: self.$selectedView) {
                            Label("sidebar.ipaLibrary", systemImage: "arrow.down.circle")
                        }
                    }
                    .onChange(of: sidebarGeom.size) { newSize in
                        navWidth = newSize.width
                    }
                    .onChange(of: colorScheme) { scheme in
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
                    .onChange(of: controlActiveState) { state in
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
                VStack {
                    switch xcodeInstallStatus {
                    case .installing:
                        if !isInstallingXcodeCli {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 45))
                                .foregroundColor(.accentColor)
                            Text("xcode.install.message")
                                .font(.title3)
                            HStack {
                                Button("button.Quit") {
                                    exit(0)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.gray)
                                .controlSize(.large)
                                Button("button.Install") {
                                    installXcodeCli()
                                    isInstallingXcodeCli = true
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.accentColor)
                                .controlSize(.large)
                            }
                        } else {
                            VStack {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                Spacer()
                                    .frame(height: 10)
                                Text("xcode.install.progress")
                                    .font(.title3)
                                Text("xcode.install.progress.subtext")
                                    .foregroundColor(.secondary)
                            }
                        }
                    case .success:
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(Color.green)
                            .font(.system(size: 45))
                            .onAppear {
                                if let sound = NSSound(named: "Glass") {
                                    sound.play()
                                }
                            }
                        Text("xcode.install.success")
                            .font(.title3)
                        Text("alert.restart")
                            .foregroundColor(.secondary)
                        Button("button.Quit") {
                            exit(0)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.accentColor)
                        .controlSize(.large)
                    case .failed:
                        Image(systemName: "xmark.octagon")
                            .foregroundColor(Color.red)
                            .font(.system(size: 45))
                            .onAppear {
                                NSSound.beep()
                            }
                        Text("xcode.install.failed")
                            .font(.title3)
                        Text("xcode.install.failed.altInstructions")
                            .foregroundColor(.secondary)
                        HStack {
                            Button("button.Quit") {
                                exit(0)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.gray)
                            .controlSize(.large)
                            Button("xcode.install.failed.altButton") {
                                NSWorkspace.shared.open(URL(string:
                                    "https://docs.playcover.io/getting_started/alt_xcode_cli_install")!)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.accentColor)
                            .controlSize(.large)
                        }
                    }
                }
                .padding()
                .frame(minWidth: 550, minHeight: 150)
            }
                .sheet(isPresented: $isSigningSetupShown) {
                    SignSetupView(isSigningSetupShown: $isSigningSetupShown)
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
                            if shell.isXcodeCliToolsInstalled {
                                isInstallingXcodeCli = false
                                xcodeInstallStatus = .success
                            } else {
                                isInstallingXcodeCli = false
                                xcodeInstallStatus = .failed
                            }
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
            var sview = superview

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
    @State static var isSigningSetupShown = true

    static var previews: some View {
        MainView(xcodeCliInstalled: $xcodeCliInstalled,
                 isSigningSetupShown: $isSigningSetupShown)
            .environmentObject(InstallVM.shared)
            .environmentObject(AppsVM.shared)
            .environmentObject(StoreVM.shared)
            .environmentObject(AppIntegrity())
    }
}
