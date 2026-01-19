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
            // 1つ目のタブ: ダッシュボード（ホーム）
            NavigationStack {
                VStack(spacing: 20) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    Text("まだデータがありません")
                        .foregroundColor(.secondary)
                        .padding(.bottom)
                    
                    // テスト用のショートカットボタン
                    Button("入力をテストする") {
                        showManualInput = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .navigationTitle("ホーム")
                // 右上に「＋」ボタンを追加
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showManualInput = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .tabItem {
                Label("ホーム", systemImage: "house")
            }
            
            // 2つ目のタブ: 履歴一覧
            // 【変更点】ここを HistoryView() に置き換えました
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
        // シート（下から出てくる画面）の設定
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
