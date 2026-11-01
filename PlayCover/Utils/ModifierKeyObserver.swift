//
//  ModifierKeyObserver.swift
//  PlayCover
//
//  Created by Venti on 14/02/2024.
//

import AppKit
import Observation

@Observable
final class ModifierKeyObserver {
    static var shared: ModifierKeyObserver { AppEnvironment.shared.modifierKeys }

    private(set) var isOptionKeyPressed = false
    private(set) var isCommandKeyPressed = false
    private(set) var isControlKeyPressed = false
    private(set) var isShiftKeyPressed = false

    // Touched from deinit, which is nonisolated under default MainActor isolation.
    @ObservationIgnored nonisolated(unsafe) private var eventMonitor: Any?

    init() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            self?.update(event.modifierFlags)
            return event
        }
    }

    private func update(_ flags: NSEvent.ModifierFlags) {
        isOptionKeyPressed = flags.contains(.option)
        isCommandKeyPressed = flags.contains(.command)
        isControlKeyPressed = flags.contains(.control)
        isShiftKeyPressed = flags.contains(.shift)
    }

    deinit {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
}
