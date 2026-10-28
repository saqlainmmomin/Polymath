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
    /// Colour for words a card marks (`marks`), matched by the same thing in its picture.
    static let mark = Color(hex: 0xF08A24)
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
    static let line   = Color(light: 0x000000, dark: 0xFFFFFF).opacity(0.08)
    /// Frosted white over the gradient: a picture's panel, a button's fill.
    static let veil   = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.06) : UIColor.white.withAlphaComponent(0.35) })
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight, design: .rounded) }

    /// Top and bottom colours of a topic's background, light then dark. Light: two clearly different pastels (sky to pink, yellow to coral) so the gradient reads.
    /// Dark: a near-black jewel tone at the top, a brighter different hue below (navy to teal, wine to crimson), never brown or olive (owner, 2026-10-27).
    static let gradients: [(light: (UInt32, UInt32), dark: (UInt32, UInt32))] = [
        ((0xA9D8FF, 0xFFC6E0), (0x0A1F45, 0x0F5A55)), ((0xFFC59A, 0xC9B5FF), (0x3D0F2A, 0x8A2A3A)),
        ((0xBBA8FF, 0xFFC9A8), (0x1B1245, 0x6A1F6E)), ((0xFFE27A, 0xFF9F9F), (0x241650, 0x9A3A50)),
        ((0x8FE8DA, 0xB4A8FF), (0x042F38, 0x2A2F80)), ((0xFFB0CF, 0xA9C8FF), (0x4A0A30, 0x2E2580)),
        ((0xC2EE8F, 0x8FDDEB), (0x08302A, 0x2A6A3A)), ((0xA9BAFF, 0xFFB3E6), (0x0F1848, 0x5A1A7A)),
        ((0xFFB49A, 0xFFE98A), (0x300A2A, 0xA0402E)), ((0x9FDCF5, 0xC4A3FF), (0x08243F, 0x3A2590)),
        ((0x8FE6C8, 0xFFE48A), (0x042E35, 0x2A5E2A)), ((0xFFB8DE, 0xFFD49A), (0x3E0E3A, 0x8A2E40)),
    ]

    /// The shade number of blueprint paper (Shazam): deep navy in light and dark alike, so its topic is always shown dark. The grid is drawn on top by `PaperGrid`.
    static let paper = -1

    static func background(_ i: Int) -> LinearGradient {
        if i == paper {
            let flat = BP.paper
            return LinearGradient(colors: [flat, flat], startPoint: .top, endPoint: .bottom)
        }
        let g = gradients[i % gradients.count]
        // 170deg in CSS: top, leaning slightly left, to bottom.
        return LinearGradient(colors: [Color(light: g.light.0, dark: g.dark.0), Color(light: g.light.1, dark: g.dark.1)],
                              startPoint: UnitPoint(x: 0.41, y: 0), endPoint: UnitPoint(x: 0.59, y: 1))
    }
}

/// Colours for a picture drawn straight onto a topic's gradient (no panel behind it): line colour, a quieter version, and one accent,
/// all taken from that gradient so they read on it in light and dark. Cards put it in the environment as `\.stage`.
struct StagePalette {
    let ink: Color
    let soft: Color
    let accent: Color
}

private struct StageKey: EnvironmentKey { static let defaultValue = S.stage(0) }
extension EnvironmentValues {
    var stage: StagePalette { get { self[StageKey.self] } set { self[StageKey.self] = newValue } }
}

extension S {
    /// Light: a deep tone of the gradient's top hue for lines and a strong shade of its bottom hue for the accent.
    /// Dark: cream warmed by the bottom colour for lines and a light tint of its hue for the accent.
    static func stage(_ i: Int) -> StagePalette {
        if i == paper {
            let ink = Color(hex: 0xEAF0FF)
            return StagePalette(ink: ink, soft: ink.opacity(0.45), accent: Color(hex: 0xF2C14E))
        }
        let g = gradients[i % gradients.count]
        func hsb(_ hex: UInt32) -> (h: CGFloat, s: CGFloat, b: CGFloat) {
            var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0
            UIColor(hex: hex).getHue(&h, saturation: &s, brightness: &b, alpha: nil)
            return (h, s, b)
        }
        let topL = hsb(g.light.0), botL = hsb(g.light.1), botD = hsb(g.dark.1)
        let ink = Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(hue: botD.h, saturation: 0.10, brightness: 1.0, alpha: 1)
            : UIColor(hue: topL.h, saturation: 0.45, brightness: 0.20, alpha: 1) })
        let accent = Color(UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(hue: botD.h, saturation: 0.50, brightness: 1.0, alpha: 1)
            : UIColor(hue: botL.h, saturation: 0.85, brightness: 0.62, alpha: 1) })
        return StagePalette(ink: ink, soft: ink.opacity(0.5), accent: accent)
    }
}
