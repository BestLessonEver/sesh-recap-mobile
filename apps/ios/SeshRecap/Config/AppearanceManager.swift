import SwiftUI

@MainActor
class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()

    @AppStorage("appearance") var appearance: Appearance = .dark {
        didSet {
            applyAppearance()
        }
    }

    enum Appearance: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"

        var colorScheme: ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }

        var icon: String {
            switch self {
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            case .system: return "circle.lefthalf.filled"
            }
        }
    }

    private init() {
        applyAppearance()
    }

    func applyAppearance() {
        // Force UI update
        objectWillChange.send()
    }
}

// MARK: - View Extension

extension View {
    func applyAppearance(_ manager: AppearanceManager) -> some View {
        self.preferredColorScheme(manager.appearance.colorScheme)
    }
}
