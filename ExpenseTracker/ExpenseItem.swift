import Foundation
import SwiftData

// MARK: - データモデル (設計図)
// @Modelをつけることで、このクラスが自動的にデータベースのテーブルとして扱われます
@Model
final class ExpenseItem {
    // ID: データ一つ一つを識別する背番号（UUIDという重複しないIDを自動生成）
    var id: UUID
    
    // 基本情報
    var date: Date          // 日付
    var title: String       // 項目名（例：ランチ）
    var amount: Int         // 金額
    var categoryRaw: String // カテゴリ（"食費"などの文字として保存）
    var isBusiness: Bool    // 経費かどうか
    var note: String        // 備考
    
    // 詳細情報（メタデータ）
    var locationFrom: String // 出発地（交通費の場合）
    var locationTo: String   // 到着地 または 店名
    
    // システム管理用
    var sourceImageHash: String // 二重投稿防止用の画像ハッシュ値
    var syncedToSheets: Bool    // スプレッドシートに送信済みか
    
    // MARK: - 初期化処理 (データの作り方)
    init(date: Date = Date(),
         title: String,
         amount: Int,
         category: ExpenseCategory = .other, // デフォルトは「その他」
         isBusiness: Bool = false,
         note: String = "",
         locationFrom: String = "",
         locationTo: String = "",
         sourceImageHash: String = "",
         syncedToSheets: Bool = false) {
        
        self.id = UUID()
        self.date = date
        self.title = title
        self.amount = amount
        self.categoryRaw = category.rawValue // Enumを文字列に変換して保存
        self.isBusiness = isBusiness
        self.note = note
        self.locationFrom = locationFrom
        self.locationTo = locationTo
        self.sourceImageHash = sourceImageHash
        self.syncedToSheets = syncedToSheets
    }
    
    // データベースには文字列(String)で保存されているが、
    // プログラム内では扱いやすいEnum(分類)として使いたいための変換機能
    var category: ExpenseCategory {
        get {
            // 文字列からEnumに変換。失敗したら .other を返す
            return ExpenseCategory(rawValue: categoryRaw) ?? .other
        }
        set {
            // Enumから文字列に変換して保存
            categoryRaw = newValue.rawValue
        }
    }
}

// MARK: - カテゴリの定義 (選択肢)
enum ExpenseCategory: String, CaseIterable, Identifiable, Codable {
    case food = "食費"
    case daily = "生活・日用品"
    case transport = "交通費"
    case entertainment = "エンタメ"
    case health = "健康・美容"
    case fixed = "固定費"
    case investment = "自己投資"
    case special = "特別支出"
    case other = "その他"
    
    var id: String { self.rawValue }
    
    // アイコン名を返す（SF Symbols）
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .daily: return "cart.fill"
        case .transport: return "tram.fill"
        case .entertainment: return "gamecontroller.fill"
        case .health: return "heart.text.square.fill"
        case .fixed: return "house.fill"
        case .investment: return "book.closed.fill"
        case .special: return "gift.fill"
        case .other: return "ellipsis.circle"
        }
    }
}
