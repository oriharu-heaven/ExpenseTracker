import SwiftUI
import GoogleGenerativeAI // 追加したSDKをインポート


struct GeminiService {
    
    // リサイズ用のヘルパーメソッドを構造体の中に追加
    private func resizeImage(image: UIImage, targetWidth: CGFloat) -> UIImage {
        let scale = targetWidth / image.size.width
        let targetHeight = image.size.height * scale
        let size = CGSize(width: targetWidth, height: targetHeight)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    
    private let apiKey = "AIzaSyABplHvPY4MMfmrXdtNfecR-96QxGUKELg"
    
    func analyzeReceipt(image: UIImage) async throws -> [ExpenseItemParsed] {
        let model = GenerativeModel(name: "gemini-2.5-flash", apiKey: apiKey)
        
        // 画像を最大幅1024pxにリサイズ（AI解析にはこれで十分です）
        let resizedImage = resizeImage(image: image, targetWidth: 1024)
        
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "画像の圧縮に失敗しました"])
        }
        
        // SDKに渡す画像を再生成
        guard let finalImage = UIImage(data: imageData) else {
            throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "画像生成に失敗しました"])
        }
        
        // 3. プロンプト（命令文）の作成
        // 設計書の「プロンプト設計」[cite: 55] に基づいて記述
        let prompt = """
        あなたは熟練の経理担当AIです。アップロードされたレシートやクレジットカード明細の画像を解析し、
        以下のJSON形式でデータを出力してください。
        Markdownのコードブロック(```jsonなど)は不要です。純粋なJSON配列のみを返してください。
        
        [
          {
            "date": "YYYY-MM-DD",
            "title": "項目名(具体的かつ簡潔に)",
            "amount": 数値(通貨記号なし),
            "category": "食費" | "生活・日用品" | "交通費" | "エンタメ" | "健康・美容" | "固定費" | "自己投資" | "特別支出" | "その他",
            "is_business": true/false (経費だと思われる場合はtrue),
            "location_from": "出発地(交通費の場合のみ)",
            "location_to": "到着地または店名"
          }
        ]
        
        画像内に複数の明細がある場合は、すべて配列に含めてください。
        """
        
        // 4. AIに送信
        let response = try await model.generateContent(prompt, resizedImage)
        
        // 5. 結果の取り出しとJSONデコード
        guard let text = response.text,
              let data = text.data(using: .utf8) else {
            throw NSError(domain: "GeminiError", code: -2, userInfo: [NSLocalizedDescriptionKey: "解析結果が空でした"])
        }
        
        // AIが余計な文字を含めた場合のクリーニング（念のため）
        let cleanText = text.replacingOccurrences(of: "```json", with: "")
                            .replacingOccurrences(of: "```", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let cleanData = cleanText.data(using: .utf8) else {
             throw NSError(domain: "GeminiError", code: -3, userInfo: [NSLocalizedDescriptionKey: "データ変換エラー"])
        }

        let decoder = JSONDecoder()
        let items = try decoder.decode([ExpenseItemParsed].self, from: cleanData)
        
        return items
    }
}
