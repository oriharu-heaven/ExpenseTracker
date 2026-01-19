import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    // 【修正1】iOS 15以降は presentationMode ではなく dismiss を使用
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        
        // 【修正2】指定されたソース（カメラ等）が利用可能かチェックして設定
        // シミュレーターでカメラを起動しようとした際のクラッシュなどを防ぎます
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            picker.sourceType = sourceType
        } else {
            // 利用できない場合はデフォルト（フォトライブラリ）などにフォールバックするか、
            // 実際の実装ではエラーハンドリングが必要ですが、ここでは安全策としてフォトライブラリを指定
            print("指定されたソースタイプは利用できません。")
            picker.sourceType = .photoLibrary
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // 通常は空でOK
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            // 【修正1】dismissアクションを実行
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
