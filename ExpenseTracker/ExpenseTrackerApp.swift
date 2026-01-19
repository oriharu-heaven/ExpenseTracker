import SwiftUI
import SwiftData

@main
struct ExpenseTrackerApp: App {
    // アプリ全体のデータベース設定
    // ここで ExpenseItem.self を指定することで、
    // 「ExpenseItem という型のデータを保存する場所を作ってね」と指示しています。
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ExpenseItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // ここでアプリ全体にデータベース機能(container)を注入します
        .modelContainer(sharedModelContainer)
    }
}
