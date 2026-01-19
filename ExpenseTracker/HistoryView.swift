import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ExpenseItem.date, order: .reverse) private var items: [ExpenseItem]
    
    // 編集画面表示用の状態変数
    @State private var selectedItem: ExpenseItem?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    // ボタンにしてタップ可能にする
                    Button {
                        selectedItem = item
                    } label: {
                        HStack {
                            Image(systemName: item.category.icon)
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text(item.title).font(.body)
                                HStack {
                                    Text(item.date, format: .dateTime.month().day())
                                    if item.isBusiness {
                                        Text("経費").font(.caption2).padding(2).background(Color.red.opacity(0.1)).foregroundColor(.red)
                                    }
                                }.font(.caption).foregroundColor(.gray)
                            }
                            Spacer()
                            Text("¥\(item.amount)").font(.headline)
                        }
                    }
                    .buttonStyle(.plain) // リストの標準的な見た目を維持
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("履歴一覧")
            .overlay {
                if items.isEmpty {
                    ContentUnavailableView("データがありません", systemImage: "list.bullet.clipboard")
                }
            }
            // シートで編集画面を開く
            .sheet(item: $selectedItem) { item in
                InputFormView(itemToEdit: item)
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}
