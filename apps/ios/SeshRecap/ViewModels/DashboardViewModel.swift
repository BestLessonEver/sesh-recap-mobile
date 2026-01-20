import Foundation

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var recentSessions: [Session] = []
    @Published var stats: DashboardStats = DashboardStats()
    @Published var isLoading = false
    @Published var error: Error?

    let sessionsViewModel: SessionsViewModel
    let clientsViewModel: ClientsViewModel

    init(sessionsViewModel: SessionsViewModel, clientsViewModel: ClientsViewModel) {
        self.sessionsViewModel = sessionsViewModel
        self.clientsViewModel = clientsViewModel
    }

    // MARK: - Load Dashboard

    func loadDashboard() async {
        isLoading = true
        error = nil

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.sessionsViewModel.loadSessions()
            }
            group.addTask {
                await self.clientsViewModel.loadClients()
            }
        }

        updateDashboardData()
        isLoading = false
    }

    func refresh() async {
        isLoading = true

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.sessionsViewModel.loadSessions(forceRefresh: true)
            }
            group.addTask {
                await self.clientsViewModel.loadClients(forceRefresh: true)
            }
        }

        updateDashboardData()
        isLoading = false
    }

    private func updateDashboardData() {
        recentSessions = Array(sessionsViewModel.sessions.prefix(5))

        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        let allSessions = sessionsViewModel.sessions

        let thisWeekSessions = allSessions.filter { $0.createdAt >= startOfWeek }
        let thisMonthSessions = allSessions.filter { $0.createdAt >= startOfMonth }

        let thisWeekMinutes = thisWeekSessions.reduce(0) { $0 + $1.durationSeconds } / 60
        let thisMonthMinutes = thisMonthSessions.reduce(0) { $0 + $1.durationSeconds } / 60

        let sentRecaps = allSessions.filter { $0.recap?.status == .sent }.count

        stats = DashboardStats(
            totalSessions: allSessions.count,
            totalClients: clientsViewModel.activeClients.count,
            thisWeekSessions: thisWeekSessions.count,
            thisMonthSessions: thisMonthSessions.count,
            thisWeekMinutes: thisWeekMinutes,
            thisMonthMinutes: thisMonthMinutes,
            sentRecaps: sentRecaps
        )
    }
}

struct DashboardStats {
    var totalSessions: Int = 0
    var totalClients: Int = 0
    var thisWeekSessions: Int = 0
    var thisMonthSessions: Int = 0
    var thisWeekMinutes: Int = 0
    var thisMonthMinutes: Int = 0
    var sentRecaps: Int = 0

    var formattedThisWeekTime: String {
        formatMinutes(thisWeekMinutes)
    }

    var formattedThisMonthTime: String {
        formatMinutes(thisMonthMinutes)
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)h \(mins)m"
        }
        return "\(minutes)m"
    }
}
