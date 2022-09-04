//
//  PlayRules.swift
//  PlayCover
//
//  Created by lucus lee on 2022/07/10.
//

import Foundation

struct PlayRules: Decodable {
    var blacklist: [String]?
    var whitelist: [String]?
    var allow: [String]?
    var bypass: [String]?

    public static func buildRules(rules: [String], bundleID: String) -> [String] {
        var result: [String] = []
        let template = RuleTemplate(data: ["NSUserName": "\(NSUserName())", "BundleID": bundleID])
        for rule in rules {
            result.append(template.render(template: rule))
        }
        return result
    }
}

@dynamicMemberLookup
struct RuleTemplate {
    private var data: [String: String]

    init(data: [String: String] = [:]) {
        self.data = data
    }

    func render(template: String) -> String {
        data.reduce(template) { $0.replacingOccurrences(of: "${\($1.key)}", with: $1.value) }
    }

    subscript(dynamicMember member: String) -> CustomStringConvertible? {
        get { data[member] }
        set { data[member] = newValue?.description }
    }

    subscript(dynamicMember member: String) -> Date {
        get { dateFormatter.date(from: data[member] ?? "") ?? Date(timeIntervalSince1970: 0) }
        set { data[member] = dateFormatter.string(from: newValue) }
    }

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }()
}
