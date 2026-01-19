import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Binding var showManualInput: Bool
    
    // データベースから全データを日付の新しい順に取得
    @Query(sort: \ExpenseItem.date, order: .reverse) private var items: [ExpenseItem]
    
    // カメラ・画像選択のための状態管理
    @State private var showCamera = false
    @State private var showPhotoLibrary = false // アルバム用
    @State private var selectedImage: UIImage?
    @State private var showScanResult = false // 解析画面を表示するフラグ
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 1. 今月の合計カード
                    TotalSummaryCard(items: currentMonthItems)
                    
                    // 2. スキャンボタンエリア（新設）
                    HStack(spacing: 16) {
                        // カメラ起動ボタン
                        Button(action: { showCamera = true }) {
                            VStack {
                                Image(systemName: "camera.viewfinder")
                                    .font(.largeTitle)
                                Text("撮影して解析")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                        
                        // アルバムから選択ボタン
                        Button(action: { showPhotoLibrary = true }) {
                            VStack {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.largeTitle)
                                Text("アルバムから")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 3. カテゴリ別チャート（データがある時だけ表示）
                    if !currentMonthItems.isEmpty {
                        VStack(alignment: .leading) {
                            Text("カテゴリ内訳")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Chart(categorySummary, id: \.category) { element in
                                SectorMark(
                                    angle: .value("金額", element.amount),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 1.5
                                )
                                .cornerRadius(5)
                                .foregroundStyle(by: .value("カテゴリ", element.category.rawValue))
                            }
                            .frame(height: 220)
                            .padding(.horizontal)
                        }
                    }
                    
                    // 4. 最近の履歴
                    VStack(alignment: .leading, spacing: 10) {
                        Text("最近の支出")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(items.prefix(3)) { item in
                            HStack {
                                Image(systemName: item.category.icon)
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.blue.opacity(0.8))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading) {
                                    Text(item.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(item.date, format: .dateTime.month().day())
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                Text("¥\(item.amount)")
                                    .fontWeight(.bold)
                            }
                            .padding()
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        if items.isEmpty {
                            Text("データがありません")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding(.vertical)
            }
            .navigationTitle("ダッシュボード")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showManualInput = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            // カメラ起動シート
            .sheet(isPresented: $showCamera) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
            }
            // アルバム起動シート
            .sheet(isPresented: $showPhotoLibrary) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
            }
            // 画像がセットされたら解析画面へ遷移
            .onChange(of: selectedImage) { oldValue, newValue in
                if newValue != nil {
                    // 0.5秒待ってから遷移させることで、ImagePickerの閉じアニメーションとの衝突を防ぐ
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showScanResult = true
                    }
                }
            }
            // 解析画面の表示
            .fullScreenCover(isPresented: $showScanResult) {
                if let img = selectedImage {
                    ScanResultView(image: img)
                }
            }
        }
    }
    
    // MARK: - 計算ロジック
    
    var currentMonthItems: [ExpenseItem] {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return []
        }
        
        return items.filter { item in
            item.date >= startOfMonth && item.date <= endOfMonth
        }
    }
    
    struct CategorySum {
        let category: ExpenseCategory
        let amount: Int
    }
    
    var categorySummary: [CategorySum] {
        let grouped = Dictionary(grouping: currentMonthItems, by: { $0.category })
        return grouped.map { category, items in
            CategorySum(category: category, amount: items.reduce(0) { $0 + $1.amount })
        }.sorted { $0.amount > $1.amount }
    }
}

// 合計金額カード（変更なし）
struct TotalSummaryCard: View {
    let items: [ExpenseItem]
    
    var totalAmount: Int {
        items.reduce(0) { $0 + $1.amount }
    }
    
    var businessAmount: Int {
        items.filter { $0.isBusiness }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text("今月の支出")
                .font(.subheadline)
                .opacity(0.8)
            
            Text("¥ \(totalAmount)")
                .font(.system(size: 42, weight: .bold))
            
            if businessAmount > 0 {
                HStack {
                    Image(systemName: "briefcase.fill")
                        .font(.caption)
                    Text("うち経費: ¥\(businessAmount)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .foregroundColor(.white)
        .cornerRadius(20)
        .padding(.horizontal)
        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    DashboardView(showManualInput: .constant(false))
        .modelContainer(for: ExpenseItem.self, inMemory: true)
}
