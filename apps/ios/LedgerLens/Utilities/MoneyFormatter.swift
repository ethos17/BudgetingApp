import Foundation

enum MoneyFormatter {
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.currencySymbol = "$"
        return f
    }()

    static func format(cents: Int) -> String {
        let decimal = Decimal(cents) / 100
        return formatter.string(from: decimal as NSDecimalNumber) ?? "$0.00"
    }
}
