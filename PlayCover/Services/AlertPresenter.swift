//
//  AlertPresenter.swift
//  PlayCover
//

import AppKit

/// Everything an alert needs, described without touching AppKit so business code can build one anywhere.
struct AlertRequest {
    struct Button {
        var title: String
        var isDefault = false
        var isDestructive = false

        static func localized(_ key: String, isDefault: Bool = false, isDestructive: Bool = false) -> Button {
            Button(title: NSLocalizedString(key, comment: ""), isDefault: isDefault, isDestructive: isDestructive)
        }
    }

    var title: String
    var message: String = ""
    var style: NSAlert.Style = .informational
    var buttons: [Button] = [.localized("button.OK")]
    /// Shows a "don't ask again" checkbox with this tooltip.
    var suppressionTooltip: String?
    var icon: NSImage?
    var accessoryView: NSView?
    /// Attach as a sheet to the main window instead of running app-modal.
    var asSheet = false
    var requestsAttention = false
}

struct AlertResponse {
    /// Index into `AlertRequest.buttons`.
    let buttonIndex: Int
    let isSuppressed: Bool

    var isFirstButton: Bool { buttonIndex == 0 }
}

/// The single place that turns `AlertRequest`s into `NSAlert`s.
final class AlertPresenter {
    static var shared: AlertPresenter { AppEnvironment.shared.alerts }

    @discardableResult
    func present(_ request: AlertRequest) async -> AlertResponse {
        let alert = makeAlert(request)
        if request.requestsAttention {
            NSApplication.shared.requestUserAttention(.criticalRequest)
        }
        let modalResponse: NSApplication.ModalResponse
        if request.asSheet, let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first {
            modalResponse = await alert.beginSheetModal(for: window)
        } else {
            modalResponse = alert.runModal()
        }
        return response(modalResponse, alert)
    }

    /// Blocking variant for synchronous call sites (menu actions, file panels).
    @discardableResult
    func presentModal(_ request: AlertRequest) -> AlertResponse {
        let alert = makeAlert(request)
        return response(alert.runModal(), alert)
    }

    func showError(_ error: Error) {
        showError(message: error.localizedDescription)
    }

    func showError(message: String) {
        Task {
            await present(AlertRequest(title: NSLocalizedString("alert.error", comment: ""),
                                       message: message, style: .critical))
        }
    }

    func showSuccess(_ message: String) {
        Task {
            await present(AlertRequest(title: NSLocalizedString("alert.success", comment: ""),
                                       message: message, style: .informational))
        }
    }

    private func makeAlert(_ request: AlertRequest) -> NSAlert {
        let alert = NSAlert()
        alert.messageText = request.title
        alert.informativeText = request.message
        alert.alertStyle = request.style
        if let icon = request.icon {
            alert.icon = icon
        }
        alert.accessoryView = request.accessoryView
        for button in request.buttons {
            let nsButton = alert.addButton(withTitle: button.title)
            nsButton.hasDestructiveAction = button.isDestructive
            if button.isDefault {
                nsButton.keyEquivalent = "\r"
            }
        }
        if let tooltip = request.suppressionTooltip {
            alert.showsSuppressionButton = true
            alert.suppressionButton?.toolTip = tooltip
        }
        return alert
    }

    private func response(_ modalResponse: NSApplication.ModalResponse, _ alert: NSAlert) -> AlertResponse {
        AlertResponse(buttonIndex: modalResponse.rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue,
                      isSuppressed: alert.suppressionButton?.state == .on)
    }
}
