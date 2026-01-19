import Foundation
import SwiftData

struct CSVImportLogic {
    
    // CSVの一行を表す一時的な型
    struct CSVRow {
        let date: Date
        let title: String
        let amount: Int
        let category: ExpenseCategory
    }
    
    enum ImportError: Error {
        case invalidFormat(line: Int)
        case invalidDate(line: Int)
        case invalidAmount(line: Int)
    }
    
    /// CSVデータを解析し、データベースに保存する
    /// - Parameters:
    ///   - csvString: CSVファイルの中身
    ///   - context: SwiftDataのコンテキスト
    /// - Returns: 成功した件数、エラーのリスト
    static func importCSV(csvString: String, context: ModelContext) -> (successCount: Int, errors: [String]) {
        let lines = csvString.components(separatedBy: .newlines)
        var successCount = 0
        var errors: [String] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd" // 想定するCSVの日付形式
        
        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // 空行やヘッダー（簡易判定）はスキップ
            if trimmedLine.isEmpty || trimmedLine.starts(with: "日付") || trimmedLine.starts(with: "date") {
                continue
            }
            
            let columns = trimmedLine.components(separatedBy: ",")
            
            // ① カラム数チェック (日付, 項目, 金額, カテゴリ の4つを想定)
            guard columns.count >= 4 else {
                errors.append("\(lineNumber)行目: フォーマット不正 (カラム不足)")
                continue
            }
            
            // ② 日付形式チェック
            guard let date = dateFormatter.date(from: columns[0]) else {
                errors.append("\(lineNumber)行目: 日付形式エラー (\(columns[0]))")
                continue
            }
            
            // ③ 金額チェック (数値かどうか、正の数か)
            guard let amount = Int(columns[2]), amount >= 0 else {
                errors.append("\(lineNumber)行目: 金額エラー (\(columns[2]))")
                continue
            }
            
            let title = columns[1]
            // カテゴリ変換（文字列からEnumへ。失敗したらその他）
            let categoryString = columns[3].trimmingCharacters(in: .whitespaces)
            let category = ExpenseCategory(rawValue: categoryString) ?? .other
            
            // データの保存
            let newItem = ExpenseItem(
                date: date,
                title: title,
                amount: amount,
                category: category,
                isBusiness: false // CSVからは一旦false
            )
            context.insert(newItem)
            successCount += 1
        }
        
        return (successCount, errors)
    }
}
