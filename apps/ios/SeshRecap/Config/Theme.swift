import SwiftUI
import UIKit

// MARK: - Brand Colors (same in both modes)
extension Color {
    // Primary brand colors - same in both modes
    static let brandPink = Color(hex: "FF69B4")
    static let brandGold = Color(hex: "FFD700")

    // Semantic colors - same in both modes
    static let success = Color(hex: "22c55e")        // Green
    static let warning = Color(hex: "FFD700")        // Gold
    static let error = Color(hex: "ef4444")          // Red

    // Initialize from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Adaptive Colors (change based on color scheme)
extension Color {
    // Background colors
    static var bgPrimary: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "030712")    // Deep dark blue
                : UIColor(hex: "f8fafc")    // Light gray-50
        })
    }

    static var bgCard: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "0c1321")    // Dark card
                : UIColor(hex: "ffffff")    // White
        })
    }

    static var bgCardEnd: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "090f1b")    // Dark card end
                : UIColor(hex: "f1f5f9")    // Light slate-100
        })
    }

    // Text colors
    static var textPrimary: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "f9fafb")    // Gray-50
                : UIColor(hex: "0f172a")    // Slate-900
        })
    }

    static var textSecondary: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "9ca3af")    // Gray-400
                : UIColor(hex: "64748b")    // Slate-500
        })
    }

    static var textTertiary: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "6b7280")    // Gray-500
                : UIColor(hex: "94a3b8")    // Slate-400
        })
    }

    // Border
    static var border: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "1e293b")    // Slate-800
                : UIColor(hex: "e2e8f0")    // Slate-200
        })
    }
}

// MARK: - UIColor Extension for hex
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

// MARK: - Brand Gradients
extension LinearGradient {
    static let brandGradient = LinearGradient(
        colors: [.brandPink, .brandGold],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let brandGradientVertical = LinearGradient(
        colors: [.brandPink, .brandGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [.bgCard, .bgCardEnd],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Reusable Components

struct BrandText: View {
    let text: String
    var font: Font = .title2
    var fontWeight: Font.Weight = .bold

    var body: some View {
        Text(text)
            .font(font)
            .fontWeight(fontWeight)
            .foregroundStyle(LinearGradient.brandGradient)
    }
}

struct GradientBlob: View {
    let color: Color
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(color.opacity(0.2))
            .frame(width: size, height: size)
            .blur(radius: 40)
    }
}

struct BrandCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content
    var padding: CGFloat = 16

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                colorScheme == .dark
                    ? AnyShapeStyle(LinearGradient.cardGradient)
                    : AnyShapeStyle(Color.bgCard)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.border, lineWidth: 1)
            )
            .shadow(color: colorScheme == .light ? .black.opacity(0.05) : .clear, radius: 8, y: 2)
    }
}

struct GradientAvatar: View {
    let name: String
    var size: CGFloat = 32

    private var initials: String {
        name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first }
            .map { String($0).uppercased() }
            .joined()
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient.brandGradientVertical)
            Text(initials.isEmpty ? "?" : initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

struct StatusPill: View {
    enum Status {
        case ready, pending, error, sent, draft

        var color: Color {
            switch self {
            case .ready, .sent: return .success
            case .pending: return .warning
            case .error: return .error
            case .draft: return .textSecondary
            }
        }

        var label: String {
            switch self {
            case .ready: return "Ready"
            case .pending: return "Pending"
            case .error: return "Error"
            case .sent: return "Sent"
            case .draft: return "Draft"
            }
        }
    }

    let status: Status

    var body: some View {
        Text(status.label)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.2))
            .foregroundStyle(status.color)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct BrandButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var style: ButtonStyle = .primary

    enum ButtonStyle {
        case primary, secondary, ghost
    }

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundView)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(isLoading)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            LinearGradient.brandGradient
        case .secondary:
            Color.bgCard
        case .ghost:
            Color.clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary, .ghost:
            return .textPrimary
        }
    }
}

struct HeroSection<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            // Background
            if colorScheme == .dark {
                LinearGradient.cardGradient
            } else {
                Color.bgCard
            }

            // Gradient blobs
            GradientBlob(color: .brandPink, size: 120)
                .offset(x: -80, y: -40)

            GradientBlob(color: .brandGold, size: 100)
                .offset(x: 100, y: 60)

            // Content
            content
                .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.border, lineWidth: 1)
        )
        .shadow(color: colorScheme == .light ? .black.opacity(0.05) : .clear, radius: 8, y: 2)
    }
}

// MARK: - View Modifiers

struct BrandBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.bgPrimary)
    }
}

extension View {
    func brandBackground() -> some View {
        modifier(BrandBackgroundModifier())
    }
}
