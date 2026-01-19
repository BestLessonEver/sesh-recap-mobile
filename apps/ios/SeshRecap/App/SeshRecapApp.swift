import SwiftUI
import Supabase

@main
struct SeshRecapApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var appearanceManager = AppearanceManager.shared

    init() {
        // Initialize Database (triggers lazy initialization)
        _ = Database.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .environmentObject(appearanceManager)
                .preferredColorScheme(appearanceManager.appearance.colorScheme)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appearanceManager: AppearanceManager

    var body: some View {
        Group {
            if authViewModel.isLoading {
                LoadingView()
            } else if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                WelcomeView()
            }
        }
        .task {
            await authViewModel.checkAuth()
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.bgPrimary
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .tint(Color.brandPink)
                Text("Loading...")
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }
}
