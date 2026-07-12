import XCTest
@testable import TLNHours

final class HACredentialsTests: XCTestCase {
    func testDecodingWithoutEntityIdDefaultsToPersonNic() throws {
        let json = #"{"baseURL":"https://ha.example.com","token":"t"}"#
        let credentials = try JSONDecoder().decode(HACredentials.self, from: Data(json.utf8))
        XCTAssertEqual(credentials.entityId, "person.nic")
    }

    func testDecodingWithEntityIdUsesProvidedValue() throws {
        let json = #"{"baseURL":"https://ha.example.com","token":"t","entityId":"person.dave"}"#
        let credentials = try JSONDecoder().decode(HACredentials.self, from: Data(json.utf8))
        XCTAssertEqual(credentials.entityId, "person.dave")
    }
}
