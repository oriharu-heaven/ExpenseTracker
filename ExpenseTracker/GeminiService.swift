import SwiftUI
import FirebaseAILogic // 最新のパッケージをインポート

struct GeminiService {
    
    // 画像リサイズ処理
    private func resizeImage(image: UIImage, targetWidth: CGFloat) -> UIImage {
        let scale = targetWidth / image.size.width
        let targetHeight = image.size.height * scale
        let size = CGSize(width: targetWidth, height: targetHeight)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    }
    
    func analyzeReceipt(image: UIImage) async throws -> [ExpenseItemParsed] {
        // 1. Firebase AI Logic の初期化
        // backend: .vertexAI() は企業向けの Vertex AI API を使用します。
        // 無料枠で試したい場合は .googleAI() に変更してください（コンソールでの設定が必要）。
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        
        // 2. モデルのインスタンス化
        let model = ai.generativeModel(modelName: "gemini-2.5-flash")
        
        let resizedImage = self.resizeImage(image: image, targetWidth: 1024)
        
        let prompt = """
        あなたは熟練の経理担当AIです。レシート画像を解析し、JSON形式でデータを出力してください。
        Markdown表記(```json)は含めず、純粋なJSON配列のみを返してください。
        
        [
          {
            "date": "YYYY-MM-DD",
            "title": "項目名",
            "amount": 数値,
            "category": "食費" | "生活・日用品" | "交通費" | "エンタメ" | "健康・美容" | "固定費" | "自己投資" | "特別支出" | "その他",
            "is_business": true/false,
            "location_from": "出発地(あれば)",
            "location_to": "到着地または店名"
          }
        ]
        """
        
        // 3. コンテンツの生成
        let response = try await model.generateContent(resizedImage, prompt)
        
        guard let text = response.text else {
            throw NSError(domain: "GeminiError", code: -2, userInfo: [NSLocalizedDescriptionKey: "解析結果が空でした"])
        }
        
        // JSONのクリーニングとデコード
        let cleanText = text.replacingOccurrences(of: "```json", with: "")
                            .replacingOccurrences(of: "```", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let cleanData = cleanText.data(using: .utf8) else {
             throw NSError(domain: "GeminiError", code: -3, userInfo: [NSLocalizedDescriptionKey: "データ変換エラー"])
        }

        return try JSONDecoder().decode([ExpenseItemParsed].self, from: cleanData)
    }
}
