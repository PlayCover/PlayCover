//
//  ModifierKeyObserver.swift
//  PlayCover
//
//  Created by Venti on 14/02/2024.
//

import Foundation

class ModifierKeyObserver: ObservableObject {
    static let shared = ModifierKeyObserver()

    @Published var isOptionKeyPressed = false
    @Published var isCommandKeyPressed = false
    @Published var isControlKeyPressed = false
    @Published var isShiftKeyPressed = false

    private var eventMonitor: Any?

    init() {
        let mask: NSEvent.EventTypeMask = [.flagsChanged]
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            guard let self = self else { return event }
            if event.type == .flagsChanged {
//                debugPrint("Event received: \(event)")
                self.isOptionKeyPressed = event.modifierFlags.contains(.option)
                self.isCommandKeyPressed = event.modifierFlags.contains(.command)
                self.isControlKeyPressed = event.modifierFlags.contains(.control)
                self.isShiftKeyPressed = event.modifierFlags.contains(.shift)
                self.objectWillChange.send()
            }
            return event
        }
    }

    deinit {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
}
