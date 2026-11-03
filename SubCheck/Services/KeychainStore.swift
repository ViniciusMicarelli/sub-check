//
//  KeychainStore.swift
//  SubCheck
//
//  Guarda pequenos valores no Keychain, que sobrevive à reinstalação do app.
//  Usado para a data de início do teste não reiniciar ao reinstalar.
//

import Foundation
import Security

enum KeychainStore {

    private static let service = "com.viniciusmicarelli.subcheck"

    private static func query(_ key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }

    static func date(for key: String) -> Date? {
        var request = query(key)
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        guard SecItemCopyMatching(request as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let text = String(data: data, encoding: .utf8),
              let seconds = TimeInterval(text) else { return nil }
        return Date(timeIntervalSince1970: seconds)
    }

    static func set(_ date: Date, for key: String) {
        let data = Data(String(date.timeIntervalSince1970).utf8)
        let status = SecItemUpdate(
            query(key) as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        if status == errSecItemNotFound {
            var item = query(key)
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(item as CFDictionary, nil)
        }
    }
}
