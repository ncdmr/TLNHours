import XCTest
@testable import TLNHours

final class PlainFileCredentialsStoreTests: XCTestCase {
    var fileURL: URL!

    override func setUp() {
        super.setUp()
        fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".cfg")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL)
        super.tearDown()
    }

    func testLoadReturnsNilWhenFileMissing() {
        let store = PlainFileCredentialsStore(fileURL: fileURL)
        XCTAssertNil(store.load())
    }

    func testSaveThenLoadRoundTrips() {
        let store = PlainFileCredentialsStore(fileURL: fileURL)
        let credentials = HACredentials(baseURL: URL(string: "https://ha.example.com")!, token: "t", entityId: "person.dave")

        store.save(credentials)

        XCTAssertEqual(store.load(), credentials)
    }

    func testClearRemovesSavedCredentials() {
        let store = PlainFileCredentialsStore(fileURL: fileURL)
        let credentials = HACredentials(baseURL: URL(string: "https://ha.example.com")!, token: "t", entityId: "person.nic")
        store.save(credentials)

        store.clear()

        XCTAssertNil(store.load())
    }

    func testSaveRestrictsFilePermissionsToOwnerOnly() throws {
        let store = PlainFileCredentialsStore(fileURL: fileURL)
        let credentials = HACredentials(baseURL: URL(string: "https://ha.example.com")!, token: "t", entityId: "person.nic")

        store.save(credentials)

        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let permissions = attributes[.posixPermissions] as? NSNumber
        XCTAssertEqual(permissions?.intValue, 0o600)
    }
}
