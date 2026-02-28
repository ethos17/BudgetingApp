import Foundation

enum APIError: Error {
    case invalidURL
    case httpStatus(Int, String?)
    case decoding(Error)
    case backend(BackendError)
}

final class APIClient {
    static let shared = APIClient()

    var baseURL: String = "http://127.0.0.1:3000" {
        didSet {
            if let url = URL(string: baseURL) {
                session.configuration.urlCredentialStorage = nil
                session.configuration.httpCookieStorage?.cookies?.forEach { session.configuration.httpCookieStorage?.deleteCookie($0) }
            }
        }
    }

    private let decoder: JSONDecoder = {
        JSONDecoder()
    }()

    private let encoder: JSONEncoder = {
        JSONEncoder()
    }()

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpShouldSetCookies = true
        config.urlCredentialStorage = nil
        return URLSession(configuration: config)
    }()

    private init() {}

    func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: (any Encodable)? = nil
    ) async throws -> T {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response) = try await session.data(for: request)
        let http = response as? HTTPURLResponse
        let status = http?.statusCode ?? 0

        if status == 401 {
            throw APIError.httpStatus(401, "Unauthorized")
        }

        if status >= 400 {
            if let err = try? JSONDecoder().decode(BackendError.self, from: data) {
                throw APIError.backend(err)
            }
            throw APIError.httpStatus(status, String(data: data, encoding: .utf8))
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    func requestVoid(path: String, method: String = "POST", body: (any Encodable)? = nil) async throws {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body = body { request.httpBody = try encoder.encode(AnyEncodable(body)) }
        let (data, response) = try await session.data(for: request)
        let http = response as? HTTPURLResponse
        let status = http?.statusCode ?? 0
        if status == 401 { throw APIError.httpStatus(401, "Unauthorized") }
        if status >= 400 {
            if let err = try? JSONDecoder().decode(BackendError.self, from: data) { throw APIError.backend(err) }
            throw APIError.httpStatus(status, String(data: data, encoding: .utf8))
        }
        // 2xx with or without body is success
    }
}

private struct AnyEncodable: Encodable {
    let value: any Encodable
    init(_ value: any Encodable) { self.value = value }
    func encode(to encoder: Encoder) throws { try value.encode(to: encoder) }
}
