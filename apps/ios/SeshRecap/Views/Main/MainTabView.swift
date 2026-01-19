import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var sessionsViewModel = SessionsViewModel()
    @StateObject private var attendantsViewModel = AttendantsViewModel()

    @State private var selectedTab = 0
    @State private var showNewSession = false

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(
                viewModel: DashboardViewModel(
                    sessionsViewModel: sessionsViewModel,
                    attendantsViewModel: attendantsViewModel
                )
            )
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            SessionListView(viewModel: sessionsViewModel)
                .tabItem {
                    Label("Sessions", systemImage: "list.bullet")
                }
                .tag(1)

            AttendantListView(viewModel: attendantsViewModel)
                .tabItem {
                    Label("Attendants", systemImage: "person.2.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .overlay(alignment: .bottom) {
            QuickRecordButton {
                showNewSession = true
            }
            .padding(.bottom, 60)
        }
        .sheet(isPresented: $showNewSession) {
            NewSessionView(
                sessionsViewModel: sessionsViewModel,
                attendantsViewModel: attendantsViewModel
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSession)) { notification in
            if let sessionId = notification.userInfo?["sessionId"] as? String,
               let uuid = UUID(uuidString: sessionId) {
                selectedTab = 1
            }
        }
    }
}

struct QuickRecordButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 64, height: 64)
                    .shadow(color: .red.opacity(0.4), radius: 8, y: 4)

                Image(systemName: "mic.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }
        .accessibilityLabel("Start new recording")
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
