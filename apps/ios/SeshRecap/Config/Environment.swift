import Foundation

enum AppConfig {
    // MARK: - Supabase
    static let supabaseURL: URL = {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let url = URL(string: urlString) else {
            fatalError("SUPABASE_URL not configured")
        }
        return url
    }()

    static let supabaseAnonKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String else {
            fatalError("SUPABASE_ANON_KEY not configured")
        }
        return key
    }()

    // MARK: - RevenueCat
    static let revenueCatAPIKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String else {
            fatalError("REVENUECAT_API_KEY not configured")
        }
        return key
    }()

    // MARK: - App Info
    static let appVersion: String = {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }()

    static let buildNumber: String = {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }()

    // MARK: - Feature Flags
    static let isDebug: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
}

// MARK: - Configuration Template (for Info.plist)
/*
 Add these keys to your Info.plist with $(VARIABLE_NAME) placeholders,
 then configure the actual values in your .xcconfig files:

 <key>SUPABASE_URL</key>
 <string>$(SUPABASE_URL)</string>
 <key>SUPABASE_ANON_KEY</key>
 <string>$(SUPABASE_ANON_KEY)</string>
 <key>REVENUECAT_API_KEY</key>
 <string>$(REVENUECAT_API_KEY)</string>
 */
