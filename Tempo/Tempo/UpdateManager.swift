import Foundation
import AppKit
import StoreKit
import Combine

final class UpdateManager: ObservableObject {
    static let shared = UpdateManager()
    
    @Published var isChecking: Bool = false
    @Published var updateAvailable: Bool = false
    @Published var latestVersion: String = ""
    @Published var releaseNotes: String = ""
    @Published var errorMessage: String?
    
    let currentVersion: String
    private let bundleId: String = "com.backtosq1.Tempo"
    private var appStoreUrl: String = ""
    
    private init() {
        self.currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
    
    func checkForUpdates() {
        isChecking = true
        errorMessage = nil
        updateAvailable = false
        
        let urlString = "https://itunes.apple.com/lookup?bundleId=\(bundleId)"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isChecking = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Tempo/1.0", forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.isChecking = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let results = json["results"] as? [[String: Any]],
                       let result = results.first {
                        
                        let storeVersion = result["version"] as? String ?? ""
                        self?.latestVersion = storeVersion
                        self?.appStoreUrl = result["trackViewUrl"] as? String ?? ""
                        
                        if let releaseNotes = result["releaseNotes"] as? String {
                            self?.releaseNotes = releaseNotes
                        }
                        
                        if self?.compareVersions(self?.currentVersion ?? "", storeVersion) == .orderedAscending {
                            self?.updateAvailable = true
                        }
                    } else {
                        self?.errorMessage = "App not found on App Store"
                    }
                } catch {
                    self?.errorMessage = "Failed to parse response"
                }
            }
        }.resume()
    }
    
    func openAppStore() {
#if os(macOS)
        if let url = URL(string: "macappstore://itunes.apple.com/app/id\(getAppStoreId())") {
            NSWorkspace.shared.open(url)
        } else if let url = URL(string: appStoreUrl) {
            NSWorkspace.shared.open(url)
        }
#else
        if let url = URL(string: appStoreUrl) {
            UIApplication.shared.open(url)
        }
#endif
    }
    
    private func getAppStoreId() -> String {
        let urlString = "https://itunes.apple.com/lookup?bundleId=\(bundleId)"
        guard let url = URL(string: urlString) else { return "" }
        
        var result = ""
        let semaphore = DispatchSemaphore(value: 0)
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]],
               let first = results.first,
               let trackId = first["trackId"] as? Int {
                result = String(trackId)
            }
            semaphore.signal()
        }.resume()
        
        _ = semaphore.wait(timeout: .now() + 5)
        return result
    }
    
    private func compareVersions(_ v1: String, _ v2: String) -> ComparisonResult {
        let v1Components = v1.split(separator: ".").compactMap { Int($0) }
        let v2Components = v2.split(separator: ".").compactMap { Int($0) }
        
        let maxLength = max(v1Components.count, v2Components.count)
        
        for i in 0..<maxLength {
            let v1Value = i < v1Components.count ? v1Components[i] : 0
            let v2Value = i < v2Components.count ? v2Components[i] : 0
            
            if v1Value < v2Value {
                return .orderedAscending
            } else if v1Value > v2Value {
                return .orderedDescending
            }
        }
        
        return .orderedSame
    }
}
