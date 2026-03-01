import Foundation

/// API calls for Plaid Link flow. Cookies are sent automatically via URLSession.
enum PlaidService {
    static func getLinkToken() async throws -> String {
        struct Response: Decodable {
            let link_token: String
        }
        let r: Response = try await APIClient.shared.request(path: "/plaid/link-token", method: "POST")
        return r.link_token
    }

    static func exchange(publicToken: String) async throws -> [Account] {
        struct Body: Encodable {
            let public_token: String
        }
        struct Response: Decodable {
            let accounts: [Account]
        }
        let r: Response = try await APIClient.shared.request(path: "/plaid/exchange", method: "POST", body: Body(public_token: publicToken))
        return r.accounts
    }

    static func sync() async throws -> (added: Int, modified: Int, removed: Int) {
        struct Response: Decodable {
            let added: Int
            let modified: Int
            let removed: Int
        }
        let r: Response = try await APIClient.shared.request(path: "/plaid/sync", method: "POST")
        return (r.added, r.modified, r.removed)
    }
}
