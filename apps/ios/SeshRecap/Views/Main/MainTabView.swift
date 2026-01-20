import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var sessionsViewModel = SessionsViewModel()
    @StateObject private var clientsViewModel = ClientsViewModel()

    @State private var selectedTab = 0
    @State private var showNewSession = false
    @State private var navigateToSessionId: UUID?

    var body: some View {
        ZStack {
            // Background
            Color.bgPrimary
                .ignoresSafeArea()

            // Content
            TabView(selection: $selectedTab) {
                DashboardView(
                    viewModel: DashboardViewModel(
                        sessionsViewModel: sessionsViewModel,
                        clientsViewModel: clientsViewModel
                    )
                )
                .tag(0)

                SessionListView(viewModel: sessionsViewModel, navigateToSessionId: $navigateToSessionId)
                    .tag(1)

                // Placeholder for record button
                Color.clear
                    .tag(2)

                ClientListView(viewModel: clientsViewModel)
                    .tag(3)

                SettingsView()
                    .tag(4)
            }

            // Custom Tab Bar
            VStack {
                Spacer()
                BrandTabBar(
                    selectedTab: $selectedTab,
                    onRecordTap: { showNewSession = true }
                )
            }
        }
        .sheet(isPresented: $showNewSession) {
            NewSessionView(
                sessionsViewModel: sessionsViewModel,
                clientsViewModel: clientsViewModel,
                onSessionCompleted: { sessionId in
                    // Navigate to the session after recording completes
                    Task { @MainActor in
                        await sessionsViewModel.loadSessions(forceRefresh: true)
                        selectedTab = 1
                        navigateToSessionId = sessionId
                    }
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .openSession)) { notification in
            if let sessionId = notification.userInfo?["sessionId"] as? String,
               let uuid = UUID(uuidString: sessionId) {
                selectedTab = 1
                navigateToSessionId = uuid
            }
        }
    }
}

// MARK: - Brand Tab Bar

struct BrandTabBar: View {
    @Binding var selectedTab: Int
    let onRecordTap: () -> Void

    private let tabs: [(icon: String, label: String, index: Int)] = [
        ("house.fill", "Home", 0),
        ("clock.fill", "Sessions", 1),
        ("person.2.fill", "Clients", 3),
        ("gearshape.fill", "Settings", 4)
    ]

    var body: some View {
        ZStack {
            // Background blur
            Rectangle()
                .fill(.ultraThinMaterial)
                .background(Color.bgPrimary.opacity(0.9))
                .frame(height: 90)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(Color.border),
                    alignment: .top
                )

            HStack(spacing: 0) {
                // Left tabs
                ForEach(tabs.prefix(2), id: \.index) { tab in
                    TabBarButton(
                        icon: tab.icon,
                        label: tab.label,
                        isSelected: selectedTab == tab.index
                    ) {
                        selectedTab = tab.index
                    }
                }

                // Center record button
                RecordButton(action: onRecordTap)
                    .offset(y: -20)

                // Right tabs
                ForEach(tabs.suffix(2), id: \.index) { tab in
                    TabBarButton(
                        icon: tab.icon,
                        label: tab.label,
                        isSelected: selectedTab == tab.index
                    ) {
                        selectedTab = tab.index
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 20)
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(isSelected ? Color.brandPink : Color.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

struct RecordButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.error)
                    .frame(width: 60, height: 60)
                    .shadow(color: .error.opacity(0.4), radius: 12, y: 4)

                Image(systemName: "mic.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Start new recording")
        .accessibilityHint("Opens the recording screen")
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
