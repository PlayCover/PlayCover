//
//  Dynamic
//  Created by Mhd Hejazi on 4/15/20.
//  Copyright © 2020 Samabox. All rights reserved.
//

import Foundation

protocol Loggable: AnyObject {
    var loggingEnabled: Bool { get }
}

extension Loggable {
    var loggingEnabled: Bool { false }
    var logUsingPrint: Bool { true }

    @discardableResult
    func log(_ items: Any...) -> Logger {
        guard loggingEnabled else { return Logger.dummy }
        return Logger.logger(for: self).log(items)
    }

    @discardableResult
    func log(_ group: Logger.Group) -> Logger {
        guard loggingEnabled else { return Logger.dummy }
        return Logger.logger(for: self).log(group)
    }
}

class Logger {
    enum Group {
        case start, end
    }

    static let dummy = DummyLogger()
    static var enabled = true

    private static var loggers: [ObjectIdentifier: Logger] = [:]
    private static var level: Int = 0

    static func logger(for object: AnyObject) -> Logger {
        let id = ObjectIdentifier(object)
        if let logger = Self.loggers[id] {
            return logger
        }

        let logger = Logger()
        Self.loggers[id] = logger

        return logger
    }

    @discardableResult
    func log(_ items: Any..., withBullet: Bool = true) -> Logger {
        log(items, withBullet: withBullet)
    }

    @discardableResult
    func log(_ items: [Any], withBullet: Bool = true) -> Logger {
        guard Self.enabled else { return self }

        let message = items.lazy.map { String(describing: $0) }.joined(separator: " ")
        var indent = String(repeating: " ╷  ", count: Self.level)
        if !indent.isEmpty, withBullet {
            indent = indent.dropLast(2) + "‣ "
        }
        print(indent + message)
        return self
    }

    @discardableResult
    func log(_ group: Group) -> Logger {
        switch group {
        case .start: logGroupStart()
        case .end: logGroupEnd()
        }
        return self
    }

    private func logGroupStart() {
        guard Self.enabled else { return }

        log([" ╭╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴"], withBullet: false)
        Self.level += 1
    }

    private func logGroupEnd() {
        guard Self.enabled else { return }

        guard Self.level > 0 else { return }
        Self.level -= 1
        log([" ╰╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴╴"], withBullet: false)
    }
}

class DummyLogger: Logger {
    @discardableResult
    override func log(_ items: [Any], withBullet: Bool = true) -> Logger {
        self
    }

    @discardableResult
    override func log(_ group: Group) -> Logger {
        self
    }
}
