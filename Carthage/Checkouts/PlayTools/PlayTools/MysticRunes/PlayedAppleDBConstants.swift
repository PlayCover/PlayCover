//
//  PlayedAppleDBConstants.swift
//  PlayTools
//
//  Created by TheMoonThatRises on 9/12/24.
//

struct PlayedAppleDBConstants {
    // https://developer.apple.com/documentation/security/keychain_services/keychain_items/item_class_keys_and_values
    // Synchronizable does not matter.
    static let primaries = [
        kSecClassGenericPassword: [
            kSecAttrAccessGroup,
            kSecAttrAccount,
            kSecAttrService
            // kSecAttrSynchronizable
        ],
        kSecClassInternetPassword: [
            kSecAttrAccessGroup,
            kSecAttrAccount,
            kSecAttrAuthenticationType,
            kSecAttrPath,
            kSecAttrPort,
            kSecAttrProtocol,
            kSecAttrSecurityDomain,
            kSecAttrServer
            // kSecAttrSynchronizable
        ],
        kSecClassCertificate: [
            kSecAttrAccessGroup,
            kSecAttrCertificateType,
            kSecAttrIssuer,
            kSecAttrSerialNumber
            // kSecAttrSynchronizable
        ],
        kSecClassKey: [
            kSecAttrAccessGroup,
            kSecAttrApplicationLabel,
            kSecAttrApplicationTag,
            kSecAttrEffectiveKeySize,
            kSecAttrKeyClass,
            kSecAttrKeySizeInBits,
            kSecAttrKeyType
            // kSecAttrSynchronizable
        ],
        kSecClassIdentity: [
            kSecAttrAccessGroup,
            kSecAttrCertificateType,
            kSecAttrIssuer,
            kSecAttrSerialNumber
            // kSecAttrSynchronizable
        ]
    ]
    static let attributes = [
        kSecClassGenericPassword: [
            kSecAttrAccessControl,
            kSecAttrAccessible,
            kSecAttrCreationDate,
            kSecAttrModificationDate,
            kSecAttrDescription,
            kSecAttrComment,
            kSecAttrCreator,
            kSecAttrType,
            kSecAttrLabel,
            kSecAttrIsInvisible,
            kSecAttrIsNegative,
            kSecAttrGeneric
        ],
        kSecClassInternetPassword: [
            kSecAttrAccessControl,
            kSecAttrAccessible,
            kSecAttrCreationDate,
            kSecAttrModificationDate,
            kSecAttrDescription,
            kSecAttrComment,
            kSecAttrCreator,
            kSecAttrType,
            kSecAttrLabel,
            kSecAttrIsInvisible,
            kSecAttrIsNegative,
            kSecAttrGeneric
        ],
        kSecClassCertificate: [
            kSecAttrCertificateEncoding,
            kSecAttrLabel,
            kSecAttrSubject,
            kSecAttrSubjectKeyID,
            kSecAttrPublicKeyHash
        ],
        kSecClassKey: [
            kSecAttrAccessible,
            kSecAttrLabel,
            kSecAttrIsPermanent,
            kSecAttrCanEncrypt,
            kSecAttrCanDecrypt,
            kSecAttrCanDerive,
            kSecAttrCanSign,
            kSecAttrCanVerify,
            kSecAttrCanWrap,
            kSecAttrCanUnwrap
        ],
        kSecClassIdentity: [
            kSecAttrCertificateEncoding,
            kSecAttrLabel,
            kSecAttrSubject,
            kSecAttrSubjectKeyID,
            kSecAttrPublicKeyHash
        ]
    ]
    static let values = [
        kSecValueData,
        kSecValueRef,
        kSecValuePersistentRef
    ]
}
