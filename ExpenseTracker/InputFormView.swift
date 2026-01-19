import SwiftUI
import SwiftData

struct InputFormView: View {
    // データベースを操作するための「環境変数」
    @Environment(\.modelContext) private var modelContext
    // 画面を閉じるための「環境変数」
    @Environment(\.dismiss) private var dismiss
    
    // 入力内容を一時的に保存しておく変数 (@State)
    @State private var date = Date()
    @State private var title = ""
    @State private var amount: Int? = nil // 最初は空欄にしたいので Optional
    @State private var category: ExpenseCategory = .food
    @State private var isBusiness = false
    @State private var note = ""
    
    // カテゴリごとの詳細項目
    @State private var locationFrom = ""
    @State private var locationTo = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    DatePicker("日付", selection: $date, displayedComponents: .date)
                    
                    HStack {
                        Text("¥")
                        TextField("金額", value: $amount, format: .number)
                            .keyboardType(.numberPad) // 数字キーボードを表示
                    }
                    
                    TextField("項目名 (例: ランチ)", text: $title)
                }
                
                Section("詳細") {
                    // カテゴリ選択ピッカー
                    Picker("カテゴリ", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                    
                    Toggle("経費として計上", isOn: $isBusiness)
                    
                    // 【重要】カテゴリによって入力欄を出し分けるロジック
                    if category == .transport {
                        TextField("出発地 (From)", text: $locationFrom)
                        TextField("到着地 (To)", text: $locationTo)
                    } else if category == .food {
                        TextField("店名", text: $locationTo)
                    } else if category == .daily {
                        TextField("購入店舗", text: $locationTo)
                    }
                    
                    TextField("備考", text: $note)
                }
            }
            .navigationTitle("支出入力")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // キャンセルボタン
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                // 保存ボタン
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveItem()
                    }
                    // タイトルか金額が空なら押せないようにする
                    .disabled(title.isEmpty || amount == nil)
                }
            }
        }
    }
    
    // データを保存する処理
    private func saveItem() {
        let newItem = ExpenseItem(
            date: date,
            title: title,
            amount: amount ?? 0, // nilなら0を入れる
            category: category,
            isBusiness: isBusiness,
            note: note,
            locationFrom: locationFrom,
            locationTo: locationTo
        )
        
        // データベースに追加！
        modelContext.insert(newItem)
        
        // 画面を閉じる
        dismiss()
    }
}

#Preview {
    InputFormView()
        // プレビュー用にメモリ内DBを用意するおまじない
        .modelContainer(for: ExpenseItem.self, inMemory: true)
}
