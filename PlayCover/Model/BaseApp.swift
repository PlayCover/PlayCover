//
//  BaseApp.swift
//  PlayCover
//

import Foundation

public class BaseApp: Identifiable, Hashable, Equatable {

    public static func == (lhs: BaseApp, rhs: BaseApp) -> Bool {
        lhs.id == rhs.id
    }

    public let id: String
    public let type: AppType

    var searchText: String {
        preconditionFailure("This method must be overridden")
    }

    public enum AppType {
        case app
        case install
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    init(id: String, type: AppType) {
        self.id = id
        self.type = type
    }
}
