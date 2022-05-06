//
//  Dynamic
//  Created by Mhd Hejazi on 4/18/20.
//  Copyright © 2020 Samabox. All rights reserved.
//

// swiftlint:disable cyclomatic_complexity syntactic_sugar

import Foundation

/// The type mapping table can be found here:
///   https://developer.apple.com/documentation/swift/imported_c_and_objective-c_apis/working_with_foundation_types
class TypeMapping {
    private static let typePairs: [(swiftType: Any.Type, objCType: AnyObject.Type)] = [
        (Array<Any>.self, NSArray.self),
        (Calendar.self, NSCalendar.self),
        (CharacterSet.self, NSCharacterSet.self),
        (Data.self, NSData.self),
        (DateComponents.self, NSDateComponents.self),
        (DateInterval.self, NSDateInterval.self),
        (Date.self, NSDate.self),
        (Decimal.self, NSDecimalNumber.self),
        (Dictionary<AnyHashable, Any>.self, NSDictionary.self),
        (IndexPath.self, NSIndexPath.self),
        (IndexSet.self, NSIndexSet.self),
        (Locale.self, NSLocale.self),
        (Notification.self, NSNotification.self),
        (PersonNameComponents.self, NSPersonNameComponents.self),
        (Set<AnyHashable>.self, NSSet.self),
        (String.self, NSString.self),
        (TimeZone.self, NSTimeZone.self),
        (URL.self, NSURL.self),
        (URLComponents.self, NSURLComponents.self),
        (URLQueryItem.self, NSURLQueryItem.self),
        (URLRequest.self, NSURLRequest.self),
        (UUID.self, NSUUID.self)
    ]

    private static let swiftToObjCTypes: [ObjectIdentifier: AnyObject.Type] = {
        let pairs = typePairs.map {
            (ObjectIdentifier($0.swiftType), $0.objCType)
        }
        return [ObjectIdentifier: AnyObject.Type](uniqueKeysWithValues: pairs)
    }()

    private static let objCToSwiftTypes: [ObjectIdentifier: Any.Type] = {
        let pairs = typePairs.map {
            (ObjectIdentifier($0.objCType), $0.swiftType)
        }
        return [ObjectIdentifier: Any.Type](uniqueKeysWithValues: pairs)
    }()

    static func swiftType(for type: Any.Type) -> Any.Type? {
        objCToSwiftTypes[ObjectIdentifier(type)]
    }

    static func objCType(for type: Any.Type) -> Any.Type? {
        swiftToObjCTypes[ObjectIdentifier(type)]
    }

    static func mappedType(for type: Any.Type) -> Any.Type? {
        swiftType(for: type) ?? objCType(for: type)
    }

    static func convertToObjCType(_ object: Any?) -> Any? {
        switch object {
        case is Array<Any>: return object as? NSArray
        case is Calendar: return object as? NSCalendar
        case is CharacterSet: return object as? NSCharacterSet
        case is Data: return object as? NSData
        case is DateComponents: return object as? NSDateComponents
        case is DateInterval: return object as? NSDateInterval
        case is Date: return object as? NSDate
        case is Decimal: return object as? NSDecimalNumber
        case is Dictionary<AnyHashable, Any>: return object as? NSDictionary
        case is IndexPath: return object as? NSIndexPath
        case is IndexSet: return object as? NSIndexSet
        case is Locale: return object as? NSLocale
        case is Notification: return object as? NSNotification
        case is PersonNameComponents: return object as? NSPersonNameComponents
        case is Set<AnyHashable>: return object as? NSSet
        case is String: return object as? NSString
        case is TimeZone: return object as? NSTimeZone
        case is URL: return object as? NSURL
        case is URLComponents: return object as? NSURLComponents
        case is URLQueryItem: return object as? NSURLQueryItem
        case is URLRequest: return object as? NSURLRequest
        case is UUID: return object as? NSUUID
        default: return nil
        }
    }

    static func convertToSwiftType(_ object: Any?) -> Any? {
        switch object {
        case is NSArray: return object as? Array<Any>
        case is NSCalendar: return object as? Calendar
        case is NSCharacterSet: return object as? CharacterSet
        case is NSData: return object as? Data
        case is NSDateComponents: return object as? DateComponents
        case is NSDateInterval: return object as? DateInterval
        case is NSDate: return object as? Date
        case is NSDecimalNumber: return object as? Decimal
        case is NSDictionary: return object as? Dictionary<AnyHashable, Any>
        case is NSIndexPath: return object as? IndexPath
        case is NSIndexSet: return object as? IndexSet
        case is NSLocale: return object as? Locale
        case is NSMeasurement: return object as? Measurement
        case is NSNotification: return object as? Notification
        case is NSPersonNameComponents: return object as? PersonNameComponents
        case is NSSet: return object as? Set<AnyHashable>
        case is NSString: return object as? String
        case is NSTimeZone: return object as? TimeZone
        case is NSURL: return object as? URL
        case is NSURLComponents: return object as? URLComponents
        case is NSURLQueryItem: return object as? URLQueryItem
        case is NSURLRequest: return object as? URLRequest
        case is NSUUID: return object as? UUID
        default: return nil
        }
    }

    static func convertType(of object: Any?) -> Any? {
        convertToObjCType(object) ?? convertToSwiftType(object)
    }
}
