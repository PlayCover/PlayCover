//
//  LoginServiceKit.swift
//  PlayCover
//
//  Created by Александр Дорофеев on 19.04.2022.
//

import Foundation

public final class LoginServiceKit: NSObject {
    private static var snapshot: (list: LSSharedFileList, items: [LSSharedFileListItem])? {
        guard let list = LSSharedFileListCreate(nil, kLSSharedFileListSessionLoginItems
            .takeRetainedValue(), nil)?.takeRetainedValue() else {
            return nil
        }
        return (list, (LSSharedFileListCopySnapshot(list, nil)?.takeRetainedValue() as? [LSSharedFileListItem]) ?? [])
    }

    public static func isExistLoginItems(at path: String = Bundle.main.bundlePath) -> Bool {
        return loginItem(at: path) != nil
    }

    @discardableResult
    public static func addLoginItems(at path: String = Bundle.main.bundlePath) -> Bool {
        guard isExistLoginItems(at: path) == false else {
            return false
        }
        guard let (list, _) = snapshot else {
            return false
        }
        let res = LoginKitWrapper.setLogin(list, path: path)
        return res
    }

    @discardableResult
    public static func removeLoginItems(at path: String = Bundle.main.bundlePath) -> Bool {
        guard isExistLoginItems(at: path) == true else {
            return false
        }
        guard let (list, items) = snapshot else {
            return false
        }
        return items.filter({
            LSSharedFileListItemCopyResolvedURL($0, 0, nil)?
                .takeRetainedValue() == (URL(fileURLWithPath: path) as CFURL) }
        ).allSatisfy {
            LSSharedFileListItemRemove(list, $0) == noErr
        }
    }

    private static func loginItem(at path: String) -> LSSharedFileListItem? {
        return snapshot?.items.first { item in
            guard let url = LSSharedFileListItemCopyResolvedURL(item, 0, nil)?.takeRetainedValue() else {
                return false
            }
            return URL(fileURLWithPath: path).absoluteString == (url as URL).absoluteString
        }
    }
}
