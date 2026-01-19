import Foundation

enum AppConfig {
    // MARK: - Supabase
    // TODO: Move to secure storage for production
    static let supabaseURL: URL = URL(string: "https://lkwxiocbnfpqglxqmsbj.supabase.co")!

    static let supabaseAnonKey: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxrd3hpb2NibmZwcWdseHFtc2JqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg3ODY4NjksImV4cCI6MjA4NDM2Mjg2OX0.rfW1zKLMayMcjkMFhahCc58o_r7mdkdwYsvcEG_hYZg"

    // MARK: - RevenueCat
    static let revenueCatAPIKey: String = "placeholder_key"

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
