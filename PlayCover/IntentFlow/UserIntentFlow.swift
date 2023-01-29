//
//  UserIntentFlow.swift
//  PlayCover
//

import Foundation

let uif = UserIntentFlow.shared

class UserIntentFlow: ObservableObject {
    static let shared = UserIntentFlow()
    var searchText = ""
    required init() { }
}
