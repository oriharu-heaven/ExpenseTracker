import SwiftUI
import SwiftData

struct HistoryView: View {
    // データベース操作用
    @Environment(\.modelContext) private var modelContext
    
    // 【重要】データベースからデータを自動で取ってくる魔法
    // sort: 日付順に並び替え, order: .reverse (新しい順)
    @Query(sort: \ExpenseItem.date, order: .reverse) private var items: [ExpenseItem]
    
    var body: some View {
        NavigationStack {
            List {
                // items配列の中身をループして表示
                ForEach(items) { item in
                    HStack {
                        // カテゴリごとのアイコン
                        Image(systemName: item.category.icon)
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text(item.title)
                                .font(.body)
                            
                            // 日付と経費フラグの表示
                            HStack {
                                Text(item.date, format: .dateTime.month().day())
                                    .foregroundColor(.gray)
                                
                                if item.isBusiness {
                                    Text("経費")
                                        .font(.caption2)
                                        .padding(.horizontal, 4)
                                        .background(Color.red.opacity(0.1))
                                        .foregroundColor(.red)
                                        .cornerRadius(4)
                                }
                            }
                            .font(.caption)
                        }
                        
                        Spacer()
                        
                        // 金額表示
                        Text("¥\(item.amount)")
                            .font(.headline)
                    }
                }
                // スワイプで削除する機能
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("履歴一覧")
            // データがない時の表示
            .overlay {
                if items.isEmpty {
                    ContentUnavailableView(
                        "データがありません",
                        systemImage: "list.bullet.clipboard",
                        description: Text("ホーム画面の＋ボタンから\n最初の支出を記録しましょう")
                    )
                }
            }
        }
    }
    
    // 削除処理
    private func deleteItems(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: ExpenseItem.self, inMemory: true)
}
