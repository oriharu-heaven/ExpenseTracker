import SwiftUI
import SwiftData
import FirebaseCore // Firebaseの初期化に必須です

@main
struct ExpenseTrackerApp: App {
    // アプリ全体のデータベース設定
    // ExpenseItem型のデータを保存するためのコンテナを作成します
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

    // 【修正箇所】SwiftUIのライフサイクルに合わせて、init()でFirebaseを初期化します
    // これにより、AI機能が呼ばれる前に確実にFirebaseの準備が整います
    init() {
        FirebaseApp.configure()
        print("Firebase successfully initialized.")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // アプリ全体にSwiftDataのデータベース機能を注入します
        .modelContainer(sharedModelContainer)
    }
}
