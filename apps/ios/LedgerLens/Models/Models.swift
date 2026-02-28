import Foundation

// MARK: - Auth & User

struct UserMe: Codable {
    let id: String
    let email: String
    let include_pending_in_budget: Bool
    let notify_on_pending: Bool
    let created_at: String
    let updated_at: String
}

// MARK: - Settings

struct Settings: Codable {
    let include_pending_in_budget: Bool
    let notify_on_pending: Bool
}

// MARK: - Categories

struct Category: Codable, Identifiable {
    let id: String
    let name: String
    let group: String
}

// MARK: - Accounts

struct Account: Codable, Identifiable {
    let id: String
    let provider: String
    let name: String
    let type: String
    let created_at: String
}

// MARK: - Transactions

struct TransactionAccount: Codable {
    let id: String
    let name: String
    let provider: String
    let type: String
}

struct TransactionCategory: Codable {
    let id: String
    let name: String
    let group: String
}

struct Transaction: Codable, Identifiable {
    let id: String
    let account: TransactionAccount
    let category: TransactionCategory?
    let merchant_name: String
    let amount_cents: Int
    let currency: String
    let status: String
    let effective_date: String
    let posted_date: String?
    let is_excluded: Bool
}

struct TransactionListResponse: Codable {
    let data: [Transaction]
    let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor
    }
}

// MARK: - Backend Error

struct BackendError: Codable {
    let error: ErrorPayload
}

struct ErrorPayload: Codable {
    let code: String
    let message: String
    let details: AnyCodable?
}

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Bool.self) { value = v }
        else if let v = try? container.decode(Int.self) { value = v }
        else if let v = try? container.decode(Double.self) { value = v }
        else if let v = try? container.decode(String.self) { value = v }
        else if let v = try? container.decode([AnyCodable].self) { value = v.map(\.value) }
        else if let v = try? container.decode([String: AnyCodable].self) { value = v.mapValues(\.value) }
        else { value = NSNull() }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as Bool: try container.encode(v)
        case let v as Int: try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as String: try container.encode(v)
        default: try container.encodeNil()
        }
    }
}

// MARK: - Date Parsing

let iso8601WithFractional: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
}()

let iso8601Standard: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime]
    return f
}()

extension Transaction {
    var effectiveDate: Date? {
        iso8601WithFractional.date(from: effective_date)
            ?? iso8601Standard.date(from: effective_date)
    }
    var postedDate: Date? {
        guard let s = posted_date else { return nil }
        return iso8601WithFractional.date(from: s) ?? iso8601Standard.date(from: s)
    }
    var isExpense: Bool { amount_cents < 0 }
}
