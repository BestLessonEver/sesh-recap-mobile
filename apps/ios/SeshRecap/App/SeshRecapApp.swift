import SwiftUI
import Supabase

@main
struct SeshRecapApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        // Initialize Supabase
        SupabaseClient.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

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
        VStack {
            ProgressView()
            Text("Loading...")
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }
}
