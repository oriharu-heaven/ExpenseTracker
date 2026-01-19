import Foundation

// AIからのレスポンス(JSON)をデコードするための構造体
struct ExpenseItemParsed: Codable {
    let date: String
    let title: String
    let amount: Int
    let category: String
    let is_business: Bool
    let location_from: String?
    let location_to: String?
}
