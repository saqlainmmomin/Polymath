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
