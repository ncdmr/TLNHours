import XCTest
@testable import TLNHours

private struct StubTransport: HTTPTransport {
    let statusCode: Int
    let body: Data

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (body, response)
    }
}

private struct ThrowingTransport: HTTPTransport {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        throw URLError(.cannotConnectToHost)
    }
}

final class HAClientTests: XCTestCase {
    let baseURL = URL(string: "https://ha.example.com")!

    func testSuccessfulFetch() async {
        let json = #"{"state":"Work","last_changed":"2026-07-10T08:00:00.000000+02:00"}"#
        let client = HAClient(baseURL: baseURL, token: "t", transport: StubTransport(statusCode: 200, body: Data(json.utf8)))

        switch await client.fetchPersonState() {
        case .success(let person):
            XCTAssertEqual(person.state, "Work")
        case .failure(let error):
            XCTFail("expected success, got \(error)")
        }
    }

    func testUnauthorized() async {
        let client = HAClient(baseURL: baseURL, token: "bad", transport: StubTransport(statusCode: 401, body: Data()))
        switch await client.fetchPersonState() {
        case .success:
            XCTFail("expected failure")
        case .failure(let error):
            XCTAssertEqual(error, .unauthorized)
        }
    }

    func testUnexpectedStatusCode() async {
        let client = HAClient(baseURL: baseURL, token: "t", transport: StubTransport(statusCode: 500, body: Data()))
        switch await client.fetchPersonState() {
        case .success:
            XCTFail("expected failure")
        case .failure(let error):
            XCTAssertEqual(error, .unexpectedResponse(500))
        }
    }

    func testMalformedBody() async {
        let client = HAClient(baseURL: baseURL, token: "t", transport: StubTransport(statusCode: 200, body: Data("not json".utf8)))
        switch await client.fetchPersonState() {
        case .success:
            XCTFail("expected failure")
        case .failure(let error):
            XCTAssertEqual(error, .decoding)
        }
    }

    func testNetworkFailure() async {
        let client = HAClient(baseURL: baseURL, token: "t", transport: ThrowingTransport())
        switch await client.fetchPersonState() {
        case .success:
            XCTFail("expected failure")
        case .failure(let error):
            guard case .network = error else {
                return XCTFail("expected .network, got \(error)")
            }
        }
    }
}
