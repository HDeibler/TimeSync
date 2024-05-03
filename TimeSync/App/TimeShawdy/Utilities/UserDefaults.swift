import Foundation

struct UserDefaultsManager {
    private enum Keys {
        static let apiKey = ""
        static let isSetupComplete = "isSetupComplete"
    }
    
    static var apiKeyExists: Bool {
        return UserDefaults.standard.string(forKey: Keys.apiKey) != nil
    }
    
    static func saveApiKey(_ apiKey: String) {
        UserDefaults.standard.set(apiKey, forKey: Keys.apiKey)
    }
    
    static func getApiKey() -> String? {
        return UserDefaults.standard.string(forKey: Keys.apiKey)
    }
    

    static var isSetupComplete: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Keys.isSetupComplete)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.isSetupComplete)
        }
    }
}
