import SwiftUI
import SwiftData

struct ContentView: View {
    // データベースへの接続口
    @Environment(\.modelContext) private var modelContext
    
    // 入力画面を表示するかどうかを管理するフラグ
    @State private var showManualInput = false

    var body: some View {
        // 画面下部にタブバーを作成
        TabView {
            // 1つ目のタブ: ダッシュボード（今回作ったリッチな画面）
            // $showManualInput とすることで、ダッシュボード側のボタンを押した時に
            // このContentViewにある showManualInput フラグを操作できるようにしています。
            DashboardView(showManualInput: $showManualInput)
                .tabItem {
                    Label("ホーム", systemImage: "house")
                }
            
            // 2つ目のタブ: 履歴一覧
            HistoryView()
                .tabItem {
                    Label("履歴", systemImage: "list.bullet")
                }
            
            // 3つ目のタブ: 設定
            NavigationStack {
                Text("ここに設定が表示されます")
                    .navigationTitle("設定")
            }
            .tabItem {
                Label("設定", systemImage: "gearshape")
            }
        }
        // シート（下から出てくる入力画面）の設定
        .sheet(isPresented: $showManualInput) {
            InputFormView()
        }
    }
}

// プレビュー用
#Preview {
    ContentView()
        .modelContainer(for: ExpenseItem.self, inMemory: true)
}
