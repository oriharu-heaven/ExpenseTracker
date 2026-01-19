import SwiftUI
import SwiftData

struct InputFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // 【追加】編集するアイテム（nilなら新規作成モード）
    var itemToEdit: ExpenseItem?
    
    @State private var date = Date()
    @State private var title = ""
    @State private var amount: Int? = nil
    @State private var category: ExpenseCategory = .food
    @State private var isBusiness = false
    @State private var note = ""
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
                            .keyboardType(.numberPad)
                    }
                    TextField("項目名", text: $title)
                }
                
                Section("詳細") {
                    Picker("カテゴリ", selection: $category) {
                        ForEach(ExpenseCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                    Toggle("経費として計上", isOn: $isBusiness)
                    
                    if category == .transport {
                        TextField("出発地", text: $locationFrom)
                        TextField("到着地", text: $locationTo)
                    } else if category == .food || category == .daily {
                        TextField("店名・購入先", text: $locationTo)
                    }
                    TextField("備考", text: $note)
                }
            }
            .navigationTitle(itemToEdit == nil ? "支出入力" : "支出の編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveItem() }
                        .disabled(title.isEmpty || amount == nil)
                }
            }
            // 画面が表示された時に、編集モードならデータを入れる
            .onAppear {
                if let item = itemToEdit {
                    date = item.date
                    title = item.title
                    amount = item.amount
                    category = item.category
                    isBusiness = item.isBusiness
                    note = item.note
                    locationFrom = item.locationFrom
                    locationTo = item.locationTo
                }
            }
        }
    }
    
    private func saveItem() {
        if let item = itemToEdit {
            // 編集モード：既存データを更新
            item.date = date
            item.title = title
            item.amount = amount ?? 0
            item.category = category
            item.isBusiness = isBusiness
            item.note = note
            item.locationFrom = locationFrom
            item.locationTo = locationTo
        } else {
            // 新規モード：新しく作ってinsert
            let newItem = ExpenseItem(
                date: date,
                title: title,
                amount: amount ?? 0,
                category: category,
                isBusiness: isBusiness,
                note: note,
                locationFrom: locationFrom,
                locationTo: locationTo
            )
            modelContext.insert(newItem)
        }
        dismiss()
    }
}
