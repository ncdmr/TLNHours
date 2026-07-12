import Foundation

enum HAClientError: Error, Equatable {
    case invalidURL
    case unauthorized
    case network(String)
    case unexpectedResponse(Int)
    case decoding
}

struct PersonState: Equatable {
    let state: String
    let lastChanged: Date
}

/// Abstracts URLSession so HAClient can be unit tested without real network calls.
protocol HTTPTransport {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPTransport {}

struct HAClient {
    let baseURL: URL
    let token: String
    var transport: HTTPTransport = URLSession.shared

    func fetchPersonState(entityId: String = "person.nic") async -> Result<PersonState, HAClientError> {
        let url = baseURL
            .appendingPathComponent("api")
            .appendingPathComponent("states")
            .appendingPathComponent(entityId)

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport.data(for: request)
        } catch {
            return .failure(.network(error.localizedDescription))
        }

        guard let http = response as? HTTPURLResponse else {
            return .failure(.network("no HTTP response"))
        }
        if http.statusCode == 401 {
            return .failure(.unauthorized)
        }
        guard http.statusCode == 200 else {
            return .failure(.unexpectedResponse(http.statusCode))
        }

        struct RawState: Decodable {
            let state: String
            let last_changed: String
        }

        guard
            let raw = try? JSONDecoder().decode(RawState.self, from: data),
            let lastChanged = HATimestamp.parse(raw.last_changed)
        else {
            return .failure(.decoding)
        }

        return .success(PersonState(state: raw.state, lastChanged: lastChanged))
    }
}
