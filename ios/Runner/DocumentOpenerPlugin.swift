import Flutter
import UIKit
import QuickLook

class DocumentOpenerPlugin: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.scanpay.document_opener", binaryMessenger: registrar.messenger())
        let instance = DocumentOpenerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "openDocument" {
            guard let args = call.arguments as? [String: Any],
                  let filePath = args["file_path"] as? String else {
                result(createResult(type: "error", message: "Invalid arguments"))
                return
            }
            
            if !isValidFileType(filePath: filePath) {
                result(createResult(type: "error", message: "Only PDF and CSV files are supported"))
                return
            }
            
            openDocument(filePath: filePath, result: result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func isValidFileType(filePath: String) -> Bool {
        let lowercasePath = filePath.lowercased()
        return lowercasePath.hasSuffix(".pdf") || lowercasePath.hasSuffix(".csv")
    }
    
    private func openDocument(filePath: String, result: @escaping FlutterResult) {
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: filePath) else {
            result(createResult(type: "error", message: "File does not exist"))
            return
        }
        
        let fileURL = URL(fileURLWithPath: filePath)
        
        DispatchQueue.main.async {
            let viewController = UIApplication.shared.windows.first?.rootViewController
            
            if UIApplication.shared.canOpenURL(fileURL) {
                UIApplication.shared.open(fileURL, options: [:], completionHandler: { success in
                    if success {
                        result(self.createResult(type: "done", message: "File opened successfully"))
                    } else {
                        result(self.createResult(type: "error", message: "Could not open file"))
                    }
                })
            } else {
                // Use QuickLook as a fallback
                let previewController = QLPreviewController()
                let previewItem = DocumentPreviewItem(url: fileURL)
                previewController.dataSource = previewItem
                
                viewController?.present(previewController, animated: true, completion: {
                    result(self.createResult(type: "done", message: "File opened successfully with QuickLook"))
                })
            }
        }
    }
    
    private func createResult(type: String, message: String) -> String {
        let result: [String: Any] = [
            "type": type,
            "message": message
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: result),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return "{\"type\":\"error\",\"message\":\"Failed to create JSON result\"}"
    }
}

class DocumentPreviewItem: NSObject, QLPreviewControllerDataSource {
    let url: URL
    
    init(url: URL) {
        self.url = url
        super.init()
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return url as QLPreviewItem
    }
} 