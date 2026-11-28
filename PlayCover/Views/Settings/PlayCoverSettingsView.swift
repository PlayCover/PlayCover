// swiftlint:disable file_length
//
//  SettingsView.swift
//  PlayCover
//
//  Created by Andrew Glaze on 7/16/22.
//

import AppKit
import Sparkle
import SwiftUI

struct GlobalBackSettingsData: Codable, Equatable {
    var titlebarBackEnabled: Bool = true
    var onlyWhenNoSidebarBackButton: Bool = true
    var includeTopCloseButtons: Bool = true
    var shortcutEnabled: Bool = true
    var shortcutKind: String = "mouse"
    var shortcutKeyCode: UInt16 = 0
    var shortcutButtonNumber: Int = 3
    var shortcutModifiersRaw: UInt = 0
    var shortcutDisplayName: String = "Mouse Button 4"
    var titlebarHomeEnabled: Bool = true
    var homeShortcutEnabled: Bool = true
    var homeShortcutKind: String = "none"
    var homeShortcutKeyCode: UInt16 = 0
    var homeShortcutButtonNumber: Int = -1
    var homeShortcutModifiersRaw: UInt = 0
    var homeShortcutDisplayName: String = ""

    static var defaultSettings: GlobalBackSettingsData { GlobalBackSettingsData() }

    init() {}

    init(from decoder: Decoder) throws {
        let dec = try decoder.container(keyedBy: CodingKeys.self), def = Self.defaultSettings
        titlebarBackEnabled = try dec.decodeIfPresent(Bool.self, forKey: .titlebarBackEnabled)
            ?? def.titlebarBackEnabled
        onlyWhenNoSidebarBackButton = try dec.decodeIfPresent(Bool.self, forKey: .onlyWhenNoSidebarBackButton)
            ?? def.onlyWhenNoSidebarBackButton
        includeTopCloseButtons = try dec.decodeIfPresent(Bool.self, forKey: .includeTopCloseButtons)
            ?? def.includeTopCloseButtons
        shortcutEnabled = try dec.decodeIfPresent(Bool.self, forKey: .shortcutEnabled) ?? def.shortcutEnabled
        shortcutKind = try dec.decodeIfPresent(String.self, forKey: .shortcutKind) ?? def.shortcutKind
        shortcutKeyCode = try dec.decodeIfPresent(UInt16.self, forKey: .shortcutKeyCode) ?? def.shortcutKeyCode
        shortcutButtonNumber = try dec.decodeIfPresent(Int.self, forKey: .shortcutButtonNumber)
            ?? def.shortcutButtonNumber
        shortcutModifiersRaw = try dec.decodeIfPresent(UInt.self, forKey: .shortcutModifiersRaw)
            ?? def.shortcutModifiersRaw
        shortcutDisplayName = try dec.decodeIfPresent(String.self, forKey: .shortcutDisplayName)
            ?? def.shortcutDisplayName
        titlebarHomeEnabled = try dec.decodeIfPresent(Bool.self, forKey: .titlebarHomeEnabled)
            ?? def.titlebarHomeEnabled
        homeShortcutEnabled = try dec.decodeIfPresent(Bool.self, forKey: .homeShortcutEnabled)
            ?? def.homeShortcutEnabled
        homeShortcutKind = try dec.decodeIfPresent(String.self, forKey: .homeShortcutKind) ?? def.homeShortcutKind
        homeShortcutKeyCode = try dec.decodeIfPresent(UInt16.self, forKey: .homeShortcutKeyCode)
            ?? def.homeShortcutKeyCode
        homeShortcutButtonNumber = try dec.decodeIfPresent(Int.self, forKey: .homeShortcutButtonNumber)
            ?? def.homeShortcutButtonNumber
        homeShortcutModifiersRaw = try dec.decodeIfPresent(UInt.self, forKey: .homeShortcutModifiersRaw)
            ?? def.homeShortcutModifiersRaw
        homeShortcutDisplayName = try dec.decodeIfPresent(String.self, forKey: .homeShortcutDisplayName)
            ?? def.homeShortcutDisplayName
    }
}

final class GlobalBackSettingsStore: ObservableObject {
    static let shared = GlobalBackSettingsStore()
    static let changedNotification = Notification.Name("io.playcover.PlayCover.GlobalBackSettingsChanged")
    static var plistURL: URL {
        PlayTools.playCoverContainer.appendingPathComponent("GlobalBackSettings.plist")
    }

    @Published var data: GlobalBackSettingsData {
        didSet {
            if !isLoading { save() }
        }
    }

    private var isLoading = false

    private init() {
        isLoading = true
        if let raw = try? Data(contentsOf: Self.plistURL),
           let decoded = try? PropertyListDecoder().decode(GlobalBackSettingsData.self, from: raw) {
            data = decoded
        } else {
            data = GlobalBackSettingsData.defaultSettings
        }
        isLoading = false
    }

    func save() {
        let dir = Self.plistURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        guard let encoded = try? encoder.encode(data) else { return }
        try? encoded.write(to: Self.plistURL, options: .atomic)
        DistributedNotificationCenter.default().postNotificationName(
            Self.changedNotification,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    func resetShortcutToDefault() {
        let defaults = GlobalBackSettingsData.defaultSettings
        data.shortcutKind = defaults.shortcutKind
        data.shortcutKeyCode = defaults.shortcutKeyCode
        data.shortcutButtonNumber = defaults.shortcutButtonNumber
        data.shortcutModifiersRaw = defaults.shortcutModifiersRaw
        data.shortcutDisplayName = defaults.shortcutDisplayName
    }

    func clearShortcut() {
        data.shortcutKind = "none"
        data.shortcutKeyCode = 0
        data.shortcutButtonNumber = -1
        data.shortcutModifiersRaw = 0
        data.shortcutDisplayName = ""
    }

    func clearHomeShortcut() {
        data.homeShortcutKind = "none"
        data.homeShortcutKeyCode = 0
        data.homeShortcutButtonNumber = -1
        data.homeShortcutModifiersRaw = 0
        data.homeShortcutDisplayName = ""
    }
}

private enum GlobalBackShortcutFormatter {
    static let relevantModifierMask: NSEvent.ModifierFlags = [.command, .option, .control, .shift]

    private static let keyLabels: [UInt16: String] = [
        36: "Return", 76: "Return", 48: "Tab", 49: "Space", 51: "Delete", 53: "Esc", 117: "Fwd Del",
        123: "←", 124: "→", 125: "↓", 126: "↑",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
        98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12"
    ]

    static func modifierPrefix(_ flags: NSEvent.ModifierFlags) -> String {
        var prefix = ""
        if flags.contains(.control) { prefix += "⌃" }
        if flags.contains(.option) { prefix += "⌥" }
        if flags.contains(.shift) { prefix += "⇧" }
        if flags.contains(.command) { prefix += "⌘" }
        return prefix
    }

    static func formatKeyboard(keyCode: UInt16, characters: String?, flags: NSEvent.ModifierFlags) -> String {
        let normalized = flags.intersection(relevantModifierMask)
        let keyLabel: String
        if let mapped = keyLabels[keyCode] {
            keyLabel = mapped
        } else {
            let cleaned = (characters ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            keyLabel = cleaned.isEmpty ? "Key \(keyCode)" : cleaned.uppercased()
        }
        return modifierPrefix(normalized) + keyLabel
    }

    static func formatMouse(buttonNumber: Int, flags: NSEvent.ModifierFlags) -> String {
        let normalized = flags.intersection(relevantModifierMask)
        let base: String
        switch buttonNumber {
        case 0: base = "Left Mouse Button"
        case 1: base = "Right Mouse Button"
        case 2: base = "Middle Mouse Button"
        default: base = "Mouse Button \(buttonNumber + 1)"
        }
        let prefix = modifierPrefix(normalized)
        return prefix.isEmpty ? base : "\(prefix) + \(base)"
    }
}

private final class GlobalBackRecorderNSView: NSView {
    var onRecordingChange: ((Bool) -> Void)?
    var onCaptured: ((String, UInt16, Int, UInt, String) -> Void)?
    private var isRecording = false {
        didSet { onRecordingChange?(isRecording) }
    }
    private var localMonitor: Any?

    deinit { stopMonitoring() }

    override var acceptsFirstResponder: Bool { true }
    override func becomeFirstResponder() -> Bool { true }

    override func resignFirstResponder() -> Bool {
        if isRecording { stopRecording() }
        return super.resignFirstResponder()
    }

    override func mouseDown(with event: NSEvent) {
        if !isRecording {
            window?.makeFirstResponder(self)
            startRecording()
        }
    }

    private func startRecording() {
        stopMonitoring()
        isRecording = true
        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] event in
            guard let self, self.isRecording else { return event }
            return self.handleCapturedEvent(event)
        }
    }

    private func stopMonitoring() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

    private func stopRecording() {
        stopMonitoring()
        isRecording = false
    }

    private func handleCapturedEvent(_ event: NSEvent) -> NSEvent? {
        let flags = event.modifierFlags.intersection(GlobalBackShortcutFormatter.relevantModifierMask)
        switch event.type {
        case .keyDown:
            if event.isARepeat { return nil }
            let display = GlobalBackShortcutFormatter.formatKeyboard(
                keyCode: event.keyCode,
                characters: event.charactersIgnoringModifiers,
                flags: flags
            )
            onCaptured?("keyboard", event.keyCode, -1, flags.rawValue, display)
            stopRecording()
            return nil
        case .leftMouseDown:
            let point = convert(event.locationInWindow, from: nil)
            if !bounds.contains(point) {
                stopRecording()
                return event
            }
            let display = GlobalBackShortcutFormatter.formatMouse(buttonNumber: event.buttonNumber, flags: flags)
            onCaptured?("mouse", 0, event.buttonNumber, flags.rawValue, display)
            stopRecording()
            return nil
        case .rightMouseDown, .otherMouseDown:
            let display = GlobalBackShortcutFormatter.formatMouse(buttonNumber: event.buttonNumber, flags: flags)
            onCaptured?("mouse", 0, event.buttonNumber, flags.rawValue, display)
            stopRecording()
            return nil
        default:
            return event
        }
    }
}

private struct GlobalBackShortcutRecorderRepresentable: NSViewRepresentable {
    @Binding var isRecording: Bool
    var onCaptured: (String, UInt16, Int, UInt, String) -> Void

    func makeNSView(context: Context) -> GlobalBackRecorderNSView {
        let view = GlobalBackRecorderNSView()
        view.onRecordingChange = { recording in
            DispatchQueue.main.async { self.isRecording = recording }
        }
        view.onCaptured = onCaptured
        return view
    }

    func updateNSView(_ nsView: GlobalBackRecorderNSView, context: Context) {
        nsView.onCaptured = onCaptured
    }
}

private struct GlobalBackRecorderField: View {
    @Binding var isRecording: Bool
    let summary: String
    let enabled: Bool
    let onCaptured: (String, UInt16, Int, UInt, String) -> Void

    var body: some View {
        let bgColor = isRecording ? Color.accentColor.opacity(0.14) : Color(NSColor.controlBackgroundColor)
        let strokeColor = isRecording ? Color.accentColor : Color.secondary.opacity(0.35)
        ZStack {
            RoundedRectangle(cornerRadius: 6).fill(bgColor)
            RoundedRectangle(cornerRadius: 6).stroke(strokeColor, lineWidth: isRecording ? 1.5 : 1)
            Text(summary)
                .font(.system(.body, design: .rounded))
                .foregroundColor(isRecording ? .accentColor : .primary)
                .lineLimit(1)
                .padding(.horizontal, 10)
            GlobalBackShortcutRecorderRepresentable(isRecording: $isRecording, onCaptured: onCaptured)
        }
        .frame(height: 28)
        .help(NSLocalizedString("preferences.globalBack.clickToRecord", comment: ""))
        .opacity(enabled ? 1.0 : 0.55)
        .allowsHitTesting(enabled)
    }
}

struct GlobalBackSettings: View {
    @ObservedObject private var store = GlobalBackSettingsStore.shared
    @State private var isRecordingBack = false
    @State private var isRecordingHome = false

    private var hasUnmodifiedLeftClickWarning: Bool {
        let backWarn = store.data.shortcutEnabled && store.data.shortcutKind == "mouse"
            && store.data.shortcutButtonNumber == 0 && store.data.shortcutModifiersRaw == 0
        let homeWarn = store.data.homeShortcutEnabled && store.data.homeShortcutKind == "mouse"
            && store.data.homeShortcutButtonNumber == 0 && store.data.homeShortcutModifiersRaw == 0
        return backWarn || homeWarn
    }

    private func shortcutSummaryText(isRecording: Bool, kind: String, displayName: String) -> String {
        if isRecording {
            return NSLocalizedString("preferences.globalBack.recordingPrompt", comment: "")
        }
        if kind == "none" || displayName.isEmpty {
            return NSLocalizedString("preferences.globalBack.notSet", comment: "")
        }
        return displayName
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("preferences.globalBack.description")
                    .font(.caption)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("preferences.globalBack.section.titlebar").font(.headline)
                    Toggle("preferences.globalBack.titlebarBackEnabled", isOn: $store.data.titlebarBackEnabled)
                    Toggle(
                        "preferences.globalBack.onlyWhenNoSidebarBackButton",
                        isOn: $store.data.onlyWhenNoSidebarBackButton
                    )
                    .disabled(!store.data.titlebarBackEnabled)
                    .padding(.leading, 20)
                    Toggle("preferences.globalBack.includeTopCloseButtons", isOn: $store.data.includeTopCloseButtons)
                    Toggle("preferences.globalBack.titlebarHomeEnabled", isOn: $store.data.titlebarHomeEnabled)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("preferences.globalBack.section.shortcut").font(.headline)
                    Toggle("preferences.globalBack.shortcutEnabled", isOn: $store.data.shortcutEnabled)
                    HStack(spacing: 10) {
                        Text("preferences.globalBack.shortcutLabel").frame(minWidth: 96, alignment: .leading)
                        GlobalBackRecorderField(
                            isRecording: $isRecordingBack,
                            summary: shortcutSummaryText(
                                isRecording: isRecordingBack,
                                kind: store.data.shortcutKind,
                                displayName: store.data.shortcutDisplayName
                            ),
                            enabled: store.data.shortcutEnabled
                        ) { kind, keyCode, buttonNumber, modifiersRaw, display in
                            store.data.shortcutKind = kind
                            store.data.shortcutKeyCode = keyCode
                            store.data.shortcutButtonNumber = buttonNumber
                            store.data.shortcutModifiersRaw = modifiersRaw
                            store.data.shortcutDisplayName = display
                        }
                        Button("preferences.globalBack.resetDefault") { store.resetShortcutToDefault() }
                        Button("preferences.globalBack.clear") { store.clearShortcut() }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("preferences.globalBack.section.homeShortcut").font(.headline)
                    Toggle("preferences.globalBack.homeShortcutEnabled", isOn: $store.data.homeShortcutEnabled)
                    HStack(spacing: 10) {
                        Text("preferences.globalBack.homeShortcutLabel").frame(minWidth: 96, alignment: .leading)
                        GlobalBackRecorderField(
                            isRecording: $isRecordingHome,
                            summary: shortcutSummaryText(
                                isRecording: isRecordingHome,
                                kind: store.data.homeShortcutKind,
                                displayName: store.data.homeShortcutDisplayName
                            ),
                            enabled: store.data.homeShortcutEnabled
                        ) { kind, keyCode, buttonNumber, modifiersRaw, display in
                            store.data.homeShortcutKind = kind
                            store.data.homeShortcutKeyCode = keyCode
                            store.data.homeShortcutButtonNumber = buttonNumber
                            store.data.homeShortcutModifiersRaw = modifiersRaw
                            store.data.homeShortcutDisplayName = display
                        }
                        Button("preferences.globalBack.clear") { store.clearHomeShortcut() }
                    }
                }

                if hasUnmodifiedLeftClickWarning {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                        Text("preferences.globalBack.warning.unmodifiedLeftClick")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(20)
        }
        .frame(width: 600, height: 420, alignment: .topLeading)
    }
}

struct PlayCoverSettingsView: View {
    @ObservedObject var updaterViewModel: UpdaterViewModel
    @EnvironmentObject var storeVM: StoreVM

    private enum Tabs: Hashable {
        case updates, ipasource, keyCover, globalBack, install, uninstall
    }

    var body: some View {
        TabView {
            UpdateSettings(updaterViewModel: updaterViewModel)
                .tabItem { Label("preferences.tab.updates", systemImage: "square.and.arrow.down") }
                .tag(Tabs.updates)
            IPASourceSettings()
                .tabItem { Label("preferences.tab.ipasource", systemImage: "list.bullet") }
                .tag(Tabs.ipasource)
                .environmentObject(storeVM)
            KeyCoverSettings.shared
                .tabItem { Label("KeyCover", systemImage: "key.fill") }
                .tag(Tabs.keyCover)
            GlobalBackSettings()
                .tabItem { Label("preferences.tab.globalBack", systemImage: "chevron.backward.circle") }
                .tag(Tabs.globalBack)
            InstallSettings.shared
                .tabItem { Label("preferences.tab.install", systemImage: "arrow.down.app") }
                .tag(Tabs.install)
            UninstallSettings.shared
                .tabItem { Label("preferences.tab.uninstall", systemImage: "trash.square") }
                .tag(Tabs.uninstall)
        }
    }
}
