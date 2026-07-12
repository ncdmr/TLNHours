import Foundation

/// Stores HA credentials as plain-text JSON at `~/.TLNHours.cfg`, restricted
/// to owner read/write. An alternative to Keychain storage for users who
/// don't want repeated Keychain-access prompts caused by this app's ad-hoc
/// code signature changing on every rebuild.
struct PlainFileCredentialsStore {
    let fileURL: URL

    init(fileURL: URL = PlainFileCredentialsStore.defaultFileURL) {
        self.fileURL = fileURL
    }

    static var defaultFileURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".TLNHours.cfg")
    }

    @discardableResult
    func save(_ credentials: HACredentials) -> Bool {
        guard let data = try? JSONEncoder().encode(credentials) else { return false }
        guard (try? data.write(to: fileURL, options: .atomic)) != nil else { return false }
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
        return true
    }

    func load() -> HACredentials? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(HACredentials.self, from: data)
    }

    @discardableResult
    func clear() -> Bool {
        (try? FileManager.default.removeItem(at: fileURL)) != nil
    }
}
