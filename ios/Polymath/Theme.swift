import SwiftUI
import UIKit

/// Design tokens, same values as core/blocks.css (light / dark).
enum T {
    static let paper  = Color(light: 0xF5F0E6, dark: 0x15130F)
    static let panel  = Color(light: 0xFBF8F2, dark: 0x1C1915)
    static let ink    = Color(light: 0x1E1A15, dark: 0xECE5D8)
    static let ink2   = Color(light: 0x5C5449, dark: 0xA79E90)
    static let rule   = Color(light: 0xD9D0C0, dark: 0x3A342C)
    static let accent = Color(light: 0xB4532A, dark: 0xE2804F)
    static let blue   = Color(light: 0x3F7DB2, dark: 0x6FAAE0)
    static let heat   = Color(light: 0xE06B22, dark: 0xFF9040)
    static let green  = Color(light: 0x4E9A4C, dark: 0x7CCB74)
    static let spark  = Color(light: 0xEDB10F, dark: 0xFFD24A)

    // System serif / monospaced stand in for Newsreader / IBM Plex Mono until the fonts are bundled.
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight, design: .serif) }
    static func mono(_ size: CGFloat = 11) -> Font { .system(size: size, weight: .medium, design: .monospaced) }
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

/// Mono labels: small, uppercase, widely spaced.
struct MonoLabel: ViewModifier {
    var size: CGFloat = 11
    func body(content: Content) -> some View {
        content.font(T.mono(size)).textCase(.uppercase).tracking(0.9)
    }
}
extension View { func monoLabel(_ size: CGFloat = 11) -> some View { modifier(MonoLabel(size: size)) } }

/// Feed shell from the Lunagraph "Learn Screen": rounded type, zinc greys, a pastel gradient behind each topic.
enum S {
    static let text  = Color(light: 0x18181B, dark: 0xF4F4F5)
    static let text2 = Color(light: 0x52525B, dark: 0xA1A1AA)
    static let faint = Color(light: 0x8B8279, dark: 0x8A847C)
    static let dotOn  = Color(light: 0x27272A, dark: 0xE4E4E7)
    static let dotOff = Color(light: 0xA1A1AA, dark: 0x52525B)
    static let line   = Color(light: 0x000000, dark: 0xFFFFFF).opacity(0.08)
    /// Frosted white over the gradient: a picture's panel, a button's fill.
    static let veil   = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.06) : UIColor.white.withAlphaComponent(0.35) })
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight, design: .rounded) }

    /// Top and bottom colours of a topic's background. The first four are the design's; the rest follow the same recipe
    /// (two pale neighbouring hues). Dark mode turns each pastel into a deep shade of the same hue.
    static let gradients: [(UInt32, UInt32)] = [
        (0xE3F1FB, 0xDDF3E8), (0xFDEFD9, 0xF8D8E2), (0xECE6FB, 0xF7E1F0), (0xFFF3D6, 0xFDE2CF),
        (0xDFF5F2, 0xE4ECFB), (0xFCE4EC, 0xEDE4FB), (0xEAF6DC, 0xFFF4D2), (0xE2E9FB, 0xF3E3FA),
        (0xFFE8DC, 0xFFF1D6), (0xDDF1F8, 0xE9E3FA), (0xF4F0DC, 0xDDF3E6), (0xF9E1F0, 0xFFE9D9),
    ]

    static func background(_ i: Int) -> LinearGradient {
        let (top, bottom) = gradients[i % gradients.count]
        // 170deg in CSS: top, leaning slightly left, to bottom. In dark mode the top is a little darker than the bottom, for depth.
        return LinearGradient(colors: [Color(light: top, dark: deep(top, lightness: 0.15)), Color(light: bottom, dark: deep(bottom, lightness: 0.21))],
                              startPoint: UnitPoint(x: 0.41, y: 0), endPoint: UnitPoint(x: 0.59, y: 1))
    }

    /// The pastel's hue at a fixed saturation and a low lightness, so sky blue becomes navy and peach becomes rust.
    private static func deep(_ hex: UInt32, lightness l: Double) -> UInt32 {
        let r = Double((hex >> 16) & 0xFF) / 255, g = Double((hex >> 8) & 0xFF) / 255, b = Double(hex & 0xFF) / 255
        let mx = max(r, g, b), mn = min(r, g, b), d = mx - mn
        var h = 0.0
        if d > 0 {
            if mx == r { h = ((g - b) / d).truncatingRemainder(dividingBy: 6) }
            else if mx == g { h = (b - r) / d + 2 }
            else { h = (r - g) / d + 4 }
            h = (h * 60 + 360).truncatingRemainder(dividingBy: 360)
        }
        let sat = 0.5
        let c = (1 - abs(2 * l - 1)) * sat, x = c * (1 - abs((h / 60).truncatingRemainder(dividingBy: 2) - 1)), m = l - c / 2
        let (r1, g1, b1): (Double, Double, Double) = switch h {
            case ..<60: (c, x, 0)
            case ..<120: (x, c, 0)
            case ..<180: (0, c, x)
            case ..<240: (0, x, c)
            case ..<300: (x, 0, c)
            default: (c, 0, x)
        }
        func ch(_ v: Double) -> UInt32 { UInt32(((v + m) * 255).rounded()) }
        return ch(r1) << 16 | ch(g1) << 8 | ch(b1)
    }
}
