import SwiftUI
import SwiftData

struct ScanResultView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // 前の画面から受け取る画像
    let image: UIImage
    
    // 画面の状態管理
    @State private var isScanning = true
    @State private var errorMessage: String?
    
    // 編集用の一時データ配列
    @State private var items: [EditableParsedItem] = []
    
    var body: some View {
        NavigationStack {
            Group {
                if isScanning {
                    // 解析中の画面
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("AIがレシートを解析中...")
                            .font(.headline)
                        Text("これには数秒かかる場合があります")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                } else if let error = errorMessage {
                    // エラー画面
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("解析に失敗しました")
                            .font(.headline)
                        Text(error)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("閉じる") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    // 解析成功：リスト表示
                    List {
                        Section {
                            ForEach($items) { $item in
                                ScannedItemRow(item: $item)
                            }
                            .onDelete { indexSet in
                                items.remove(atOffsets: indexSet)
                            }
                        } header: {
                            Text("\(items.count)件の支出が見つかりました")
                        } footer: {
                            Text("項目をタップして編集、スワイプして削除できます")
                        }
                    }
                }
            }
            .navigationTitle("スキャン結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("すべて保存") {
                        saveAllItems()
                    }
                    .disabled(isScanning || items.isEmpty)
                }
            }
            // 画面が表示されたら自動で解析開始
            .task {
                await analyzeImage()
            }
        }
    }
    
    // AI解析処理
    private func analyzeImage() async {
        let service = GeminiService()
        do {
            // 画像を送信して結果を待つ
            let result = try await service.analyzeReceipt(image: image)
            
            // 成功したら編集用データに変換して表示
            await MainActor.run {
                self.items = result.map { EditableParsedItem(from: $0) }
                self.isScanning = false
            }
        } catch {
            // エラー時
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isScanning = false
            }
        }
    }
    
    // DBへの保存処理
    private func saveAllItems() {
        for item in items {
            // 日付文字列 (YYYY-MM-DD) を Date型に変換
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            // 日付変換に失敗したら今日の日付にする
            let date = dateFormatter.date(from: item.date) ?? Date()
            
            // カテゴリ文字列をEnumに変換
            let category = ExpenseCategory(rawValue: item.category) ?? .other
            
            // 本番用データモデルを作成
            let newItem = ExpenseItem(
                date: date,
                title: item.title,
                amount: item.amount,
                category: category,
                isBusiness: item.isBusiness,
                note: "", // メモは一旦空で
                locationFrom: item.locationFrom ?? "",
                locationTo: item.locationTo ?? ""
            )
            
            // DBに追加
            modelContext.insert(newItem)
        }
        
        dismiss()
    }
}

// 編集用の一時構造体（View内で書き換えるため var になっている）
struct EditableParsedItem: Identifiable {
    let id = UUID()
    var date: String
    var title: String
    var amount: Int
    var category: String
    var isBusiness: Bool
    var locationFrom: String?
    var locationTo: String?
    
    // APIからのレスポンスを変換するイニシャライザ
    init(from parsed: ExpenseItemParsed) {
        self.date = parsed.date
        self.title = parsed.title
        self.amount = parsed.amount
        self.category = parsed.category
        self.isBusiness = parsed.is_business
        self.locationFrom = parsed.location_from
        self.locationTo = parsed.location_to
    }
}

// リストの各行（編集機能付き）
struct ScannedItemRow: View {
    @Binding var item: EditableParsedItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // 日付（YYYY-MM-DD形式のテキストとして編集）
                TextField("日付", text: $item.date)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 90)
                
                // タイトル
                TextField("項目名", text: $item.title)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            HStack {
                // カテゴリ（簡易表示）
                Text(item.category)
                    .font(.caption2)
                    .padding(4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                // 経費スイッチ
                Toggle(isOn: $item.isBusiness) {
                    Text("経費")
                        .font(.caption2)
                        .foregroundColor(item.isBusiness ? .red : .gray)
                }
                .toggleStyle(.button)
                .font(.caption2)
                .tint(.red.opacity(0.1))
                
                Spacer()
                
                // 金額
                HStack(spacing: 2) {
                    Text("¥")
                        .foregroundColor(.secondary)
                    TextField("金額", value: $item.amount, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .font(.headline)
                }
                .frame(width: 100)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    // プレビュー用ダミーデータは画像がないので動きませんが、画面確認用
    Text("実機またはシミュレータで確認してください")
}
