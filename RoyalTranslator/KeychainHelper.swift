import Foundation
import Security

enum KeychainHelper {
    private static let service    = "com.JFG3rd.RoyalTranslator"
    private static let account    = "anthropic-api-key"
    private static let installKey = "com.JFG3rd.RoyalTranslator.installedBefore"

    // MARK: - Fresh-install wipe
    //
    // iOS does not delete Keychain items when the app is deleted — they survive
    // reinstallation. We detect a fresh install via a UserDefaults sentinel: if
    // the flag is absent this is either the very first install or a reinstall
    // after deletion, so we proactively wipe any lingering key before use.

    static func wipeIfReinstalled() {
        guard !UserDefaults.standard.bool(forKey: installKey) else { return }
        delete()
        UserDefaults.standard.set(true, forKey: installKey)
    }

    // MARK: - CRUD

    static func save(_ value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String:                kSecClassGenericPassword,
            kSecAttrService as String:          service,
            kSecAttrAccount as String:          account
        ]
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String]           = data
        // Device-only, never synced to iCloud Keychain
        attributes[kSecAttrSynchronizable as String]  = kCFBooleanFalse
        // Accessible after first unlock; still wiped on fresh install via sentinel above
        attributes[kSecAttrAccessible as String]      = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String:                kSecClassGenericPassword,
            kSecAttrService as String:          service,
            kSecAttrAccount as String:          account,
            kSecReturnData as String:           true,
            kSecMatchLimit as String:           kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete() {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
