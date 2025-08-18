//
//  PlayWeRuinedIt.swift
//  PlayTools
//
//  Created by Venti on 16/01/2023.
//

import Foundation
import Security

// Implementation for PlayKeychain
// World's Most Advanced Keychain Replacement Solution:tm:
// This is a joke, don't take it seriously

public class PlayKeychain: NSObject {
    static let shared = PlayKeychain()
    private static let playChainDB = PlayKeychainDB.shared

    @objc public static func debugLogger(_ logContent: String) {
        if PlaySettings.shared.settingsData.playChainDebugging {
            NSLog("PC-DEBUG: \(logContent)")
        }
    }
    // Emulates SecItemAdd, SecItemUpdate, SecItemDelete and SecItemCopyMatching
    // Store the entire dictionary as a plist
    // SecItemAdd(CFDictionaryRef attributes, CFTypeRef *result)
    @objc static public func add(_ attributes: NSDictionary,
                                 result: UnsafeMutablePointer<Unmanaged<CFTypeRef>?>?) -> OSStatus {
        guard let keychainDict = playChainDB.insert(attributes) else {
            debugLogger("Failed to write keychain file")
            return errSecIO
        }
        debugLogger("Wrote keychain item to db")
        // Place v_Data in the result
        guard let vData = attributes["v_Data"] as? CFTypeRef else {
            return errSecSuccess
        }

        if attributes["r_Attributes"] as? Int == 1 {
            // Create a dummy dictionary and return it
            let dummyDict = keychainDict
            if attributes["r_Data"] as? Int != 1 {
                dummyDict.removeObject(forKey: kSecValueData)
                dummyDict.removeObject(forKey: kSecValueRef)
                dummyDict.removeObject(forKey: kSecValuePersistentRef)
            }
            result?.pointee = Unmanaged.passRetained(dummyDict)
            return errSecSuccess
        }

        if attributes["class"] as? String == "keys" {
            // kSecAttrKeyType is stored as `type` in the dictionary
            // kSecAttrKeyClass is stored as `kcls` in the dictionary
            let keyAttributes = [
                kSecAttrKeyType: attributes["type"] as! CFString, // swiftlint:disable:this force_cast
                kSecAttrKeyClass: attributes["kcls"] as! CFString // swiftlint:disable:this force_cast
            ]
            let keyData = vData as! Data // swiftlint:disable:this force_cast
            let key = SecKeyCreateWithData(keyData as CFData, keyAttributes as CFDictionary, nil)
            result?.pointee = Unmanaged.passRetained(key!)
            return errSecSuccess
        }
        result?.pointee = Unmanaged.passRetained(vData)
        return errSecSuccess
    }

    // SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate)
    @objc static public func update(_ query: NSDictionary, attributesToUpdate: NSDictionary) -> OSStatus {
        guard let keychainDict = playChainDB.query(query)?.first else {
            debugLogger("Keychain item not found in db")
            return errSecItemNotFound
        }
        debugLogger("Select keychain item from db")
        // Reconstruct the dictionary (subscripting won't work as assignment is not allowed)
        let newKeychainDict = NSMutableDictionary()
        for (key, value) in keychainDict {
            newKeychainDict.setValue(value, forKey: key as! String) // swiftlint:disable:this force_cast
        }
        // Update the dictionary
        for (key, value) in attributesToUpdate {
            newKeychainDict.setValue(value, forKey: key as! String) // swiftlint:disable:this force_cast
        }
        guard playChainDB.update(newKeychainDict) else {
            debugLogger("Failed to update keychain item to db")
            return errSecIO
        }

        return errSecSuccess
    }

    // SecItemDelete(CFDictionaryRef query)
    @objc static public func delete(_ query: NSDictionary) -> OSStatus {
        guard playChainDB.query(query)?.first != nil else {
            debugLogger("Failed to find keychain item")
            return errSecItemNotFound
        }
        guard playChainDB.delete(query) else {
            debugLogger("Failed to delete keychain item")
            return errSecIO
        }
        debugLogger("Deleted keychain item in db")
        return errSecSuccess
    }

    // SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result)
    // swiftlint:disable:next function_body_length
    @objc static public func copyMatching(_ query: NSDictionary,
                                          result: UnsafeMutablePointer<Unmanaged<CFTypeRef>?>?) -> OSStatus {
        guard let keychainDicts = playChainDB.query(query),
              let keychainDict = keychainDicts.first else {
            debugLogger("Keychain item not found in db")
            return errSecItemNotFound
        }

        if query[kSecMatchLimit as String] as? String ==  kSecMatchLimitAll as String {
            result?.pointee = Unmanaged.passRetained(keychainDicts.map({
                $0.removeObject(forKey: kSecValueData)
                $0.removeObject(forKey: kSecValueRef)
                $0.removeObject(forKey: kSecValuePersistentRef)
                return $0
            }) as CFTypeRef)
            return errSecSuccess
        }
        // Check the `r_Attributes` key. If it is set to 1 in the query
        let classType = query[kSecClass as String] as? String ?? ""

        if query["r_Attributes"] as? Int == 1 {
            // Create a dummy dictionary and return it
            let dummyDict = keychainDict
            if query["r_Data"] as? Int != 1 {
                dummyDict.removeObject(forKey: kSecValueData)
                dummyDict.removeObject(forKey: kSecValueRef)
                dummyDict.removeObject(forKey: kSecValuePersistentRef)
            }
            result?.pointee = Unmanaged.passRetained(dummyDict)
            return errSecSuccess
        }

        // Check for r_Ref
        if query["r_Ref"] as? Int == 1 {
            // Return the data on v_PersistentRef or v_Data if they exist
            var key: CFTypeRef?
            if let vData = keychainDict[kSecValueData] {
                NSLog("found v_Data")
                debugLogger("Read keychain item from db")
                key = vData as CFTypeRef
            }
            if let vPersistentRef = keychainDict[kSecValuePersistentRef] {
                NSLog("found persistent ref")
                debugLogger("Read keychain item from db")
                key = vPersistentRef as CFTypeRef
            }

            if key == nil {
                debugLogger("Keychain item not found in db")
                return errSecItemNotFound
            }

            let dummyKeyAttrs = [
                kSecAttrKeyType: keychainDict[kSecAttrKeyType] ?? kSecAttrKeyTypeRSA,
                kSecAttrKeyClass: keychainDict[kSecAttrKeyClass] ?? kSecAttrKeyClassPublic
            ] as CFDictionary

            let secKey = SecKeyCreateWithData(key as! CFData, dummyKeyAttrs, nil) // swiftlint:disable:this force_cast
            result?.pointee = Unmanaged.passRetained(secKey!)
            return errSecSuccess
        }

        // Return v_Data if it exists
        if let vData = keychainDict[kSecValueData] {
            debugLogger("Read keychain file from db")
            // Check the class type, if it is a key we need to return the data
            // as SecKeyRef, otherwise we can return it as a CFTypeRef
            if classType == "keys" {
                // kSecAttrKeyType is stored as `type` in the dictionary
                // kSecAttrKeyClass is stored as `kcls` in the dictionary
                let keyAttributes = [
                    kSecAttrKeyType: keychainDict[kSecAttrKeyType] as! CFString, // swiftlint:disable:this force_cast
                    kSecAttrKeyClass: keychainDict[kSecAttrKeyClass] as! CFString // swiftlint:disable:this force_cast
                ]
                let keyData = vData as! Data // swiftlint:disable:this force_cast
                let key = SecKeyCreateWithData(keyData as CFData, keyAttributes as CFDictionary, nil)
                result?.pointee = Unmanaged.passRetained(key!)
                return errSecSuccess
            }
            result?.pointee = Unmanaged.passRetained(vData as CFTypeRef)
            return errSecSuccess
        }

        return errSecItemNotFound
    }
}
