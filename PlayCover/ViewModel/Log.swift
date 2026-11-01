//
//  Logger.swift
//  PlayCover
//

import Foundation

/// Session log (copied from the menu bar) plus the user-facing error / success dialogs.
final class Log {

    static var shared: Log { AppEnvironment.shared.log }

    private let alerts: AlertPresenter

    init(alerts: AlertPresenter) {
        self.alerts = alerts
    }

    func error(_ err: Error) {
        log(err.localizedDescription, isError: true)
        alerts.showError(err)
    }

    func error(localized str: String, args: [String] = []) {
        error(String(format: NSLocalizedString(str, comment: ""), arguments: args))
    }

    func msg(_ msg: String) {
        log(msg)
        alerts.showSuccess(msg)
    }

    private(set) var logdata = "\(ProcessInfo.processInfo.operatingSystemVersionString)\n"

    func log(_ str: String, isError: Bool = false) {
        print(str)
        if isError {
            logdata.append("ERROR: ")
        }
        logdata.append(str)
        logdata.append("\n")
    }
}
