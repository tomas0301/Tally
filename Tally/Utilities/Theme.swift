import SwiftUI

enum Theme {
    // MARK: - Colors
    static let primary = Color(hex: "4361EE")      // Vivid Blue
    static let secondary = Color(hex: "3F37C9")    // Deep Indigo
    static let accent = Color(hex: "F72585")       // Vibrant Pink
    static let background = Color(hex: "F8F9FA")   // Off-white/Light Gray
    static let surface = Color.white
    static let textPrimary = Color(hex: "212529")
    static let textSecondary = Color(hex: "6C757D")
    
    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "4361EE"), Color(hex: "3F37C9")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Layout
    static let padding: CGFloat = 16
    static let cornerRadius: CGFloat = 16
    static let buttonHeight: CGFloat = 50
    
    // MARK: - Shadows
    static func shadow(radius: CGFloat = 10, y: CGFloat = 4, opacity: Double = 0.1) -> some ViewModifier {
        ShadowModifier(radius: radius, y: y, opacity: opacity)
    }
    
    // MARK: - Typography
    // Using system fonts for now, but configured for hierarchy
}

struct ShadowModifier: ViewModifier {
    let radius: CGFloat
    let y: CGFloat
    let opacity: Double
    
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(opacity), radius: radius, x: 0, y: y)
    }
}

// MARK: - Helper for Hex Colors
extension Color {
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
