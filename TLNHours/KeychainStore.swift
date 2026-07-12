import Foundation
import Security

struct HACredentials: Codable, Equatable {
    let baseURL: URL
    let token: String
    let entityId: String

    init(baseURL: URL, token: String, entityId: String) {
        self.baseURL = baseURL
        self.token = token
        self.entityId = entityId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        baseURL = try container.decode(URL.self, forKey: .baseURL)
        token = try container.decode(String.self, forKey: .token)
        entityId = try container.decodeIfPresent(String.self, forKey: .entityId) ?? "person.nic"
    }
}

enum KeychainStore {
    private static let service = "com.ncdmr.tlnhours"
    private static let account = "ha-credentials"

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    @discardableResult
    static func save(_ credentials: HACredentials) -> Bool {
        guard let data = try? JSONEncoder().encode(credentials) else { return false }

        SecItemDelete(baseQuery as CFDictionary)

        var attributes = baseQuery
        attributes[kSecValueData as String] = data
        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }

    static func load() -> HACredentials? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(HACredentials.self, from: data)
    }

    @discardableResult
    static func clear() -> Bool {
        SecItemDelete(baseQuery as CFDictionary) == errSecSuccess
    }
}
