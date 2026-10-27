import SwiftUI

/// First launch only: a name, then interests, then straight to the feed.
struct OnboardingView: View {
    @Environment(Profile.self) private var profile
    @State private var step = 0
    @State private var name = ""
    @State private var picked: Set<String> = []

    var body: some View {
        ZStack {
            T.paper.ignoresSafeArea()
            if step == 0 {
                NameStep(name: $name) { withAnimation(.easeInOut(duration: 0.3)) { step = 1 } }
                    .transition(.asymmetric(insertion: .identity, removal: .move(edge: .leading).combined(with: .opacity)))
            } else {
                InterestsStep(name: name, picked: $picked,
                              back: { withAnimation(.easeInOut(duration: 0.3)) { step = 0 } },
                              done: { profile.finish(name: name, interests: picked) })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }
}

private struct NameStep: View {
    @Binding var name: String
    let next: () -> Void
    @FocusState private var focused: Bool
    private var ready: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text("Polymath").monoLabel().foregroundStyle(T.accent)
            Text("What should we call you?").font(T.serif(38, .medium)).foregroundStyle(T.ink)
                .padding(.top, 12).fixedSize(horizontal: false, vertical: true)
            Text("No sign-up. Just a name, kept on this phone.").font(T.serif(18)).foregroundStyle(T.ink2).padding(.top, 10)
            TextField("", text: $name, prompt: Text("Your first name").foregroundStyle(T.ink2.opacity(0.6)))
                .font(T.serif(28)).foregroundStyle(T.ink)
                .textContentType(.givenName).textInputAutocapitalization(.words).autocorrectionDisabled()
                .submitLabel(.continue).focused($focused)
                .onSubmit { if ready { next() } }
                .padding(.top, 32).padding(.bottom, 10)
                .overlay(alignment: .bottom) { Rectangle().fill(focused ? T.accent : T.rule).frame(height: 2) }
            Spacer()
            PrimaryButton(title: "Continue", enabled: ready, action: next)
        }
        .padding(.horizontal, 24).padding(.bottom, 16)
        .background {
            ZStack {
                Circle().fill(Color(hex: 0xFF8A3D).opacity(0.5)).frame(width: 300).blur(radius: 70).offset(x: 110, y: -260)
                Circle().fill(Color(hex: 0x6FAAE0).opacity(0.4)).frame(width: 260).blur(radius: 70).offset(x: -130, y: 220)
            }
            .allowsHitTesting(false)
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focused = true } }
    }
}

/// Lunagraph "Interest Picker": a two-column grid of tiles (icon over label), with a count and Continue pinned at the bottom.
private struct InterestsStep: View {
    let name: String
    @Binding var picked: Set<String>
    let back: () -> Void
    let done: () -> Void
    private let maximum = 7

    // Zinc greys from the design, inverted for dark mode.
    private let bg = Color(light: 0xFFFFFF, dark: 0x09090B)
    private let title = Color(light: 0x18181B, dark: 0xF4F4F5)
    private let body2 = Color(light: 0x71717A, dark: 0xA1A1AA)
    private let label = Color(light: 0x3F3F46, dark: 0xD4D4D8)
    private let faint = Color(light: 0xA1A1AA, dark: 0x71717A)
    private let border = Color(light: 0xE4E4E7, dark: 0x27272A)
    private let off = Color(light: 0xF4F4F5, dark: 0x18181B)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: back) { Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold)).foregroundStyle(body2).frame(width: 44, height: 44, alignment: .leading) }
                        .accessibilityLabel("Back")
                    Text("Tell us your interests, \(name.trimmingCharacters(in: .whitespaces))").font(.system(size: 24, weight: .medium, design: .rounded)).foregroundStyle(title)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Pick up to \(maximum) topics. We'll fill your feed with them.").font(.system(size: 16, design: .rounded)).foregroundStyle(body2)
                        .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(Subject.all, id: \.name) { s in
                        let on = picked.contains(s.name)
                        Tile(subject: s, on: on, full: !on && picked.count >= maximum, label: label, faint: faint, border: border) { toggle(s.name) }
                    }
                }
            }
            .padding(.horizontal, 21)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .background(bg.ignoresSafeArea())
    }

    private func toggle(_ s: String) {
        if picked.contains(s) { picked.remove(s) }
        else if picked.count < maximum { picked.insert(s) }
        else { UINotificationFeedbackGenerator().notificationOccurred(.warning); return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private var bottomBar: some View {
        HStack {
            (Text("\(picked.count)").foregroundStyle(picked.isEmpty ? faint : title) + Text("/\(maximum) selected"))
                .font(.system(size: 16, weight: .medium, design: .rounded)).foregroundStyle(label)
                .contentTransition(.numericText()).animation(.snappy, value: picked.count)
            Spacer()
            Button(action: done) {
                Text("Continue").font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(picked.isEmpty ? faint : bg)
                    .frame(width: 170, height: 52)
                    .background(Capsule().fill(picked.isEmpty ? off : title))
            }
            .disabled(picked.isEmpty)
            .animation(.easeOut(duration: 0.2), value: picked.isEmpty)
        }
        .padding(.horizontal, 21).padding(.top, 14).padding(.bottom, 8)
        .background(alignment: .top) {
            // Tiles fade out under the bar instead of being cut off.
            LinearGradient(colors: [bg.opacity(0), bg], startPoint: .top, endPoint: .bottom).frame(height: 64).offset(y: -64)
                .allowsHitTesting(false)
        }
        .background(bg.ignoresSafeArea(edges: .bottom))
    }
}

/// One choice: a coloured line icon over its name. Picked = tinted fill, coloured outline and a tick.
private struct Tile: View {
    let subject: (name: String, icon: String, color: Color)
    let on: Bool
    let full: Bool
    let label: Color
    let faint: Color
    let border: Color
    let tap: () -> Void

    var body: some View {
        Button(action: tap) {
            VStack(spacing: 8) {
                Image(systemName: subject.icon).font(.system(size: 24, weight: on ? .regular : .light)).foregroundStyle(subject.color)
                    .frame(height: 28)
                Text(subject.name).font(.system(size: 16, weight: on ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(full ? faint : label)
            }
            .frame(maxWidth: .infinity).frame(height: 100)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(subject.color.opacity(on ? 0.1 : 0)))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(on ? subject.color : border, lineWidth: on ? 1.5 : 1))
            .overlay(alignment: .topTrailing) {
                if on {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 18)).foregroundStyle(subject.color)
                        .padding(8).transition(.scale.combined(with: .opacity))
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(Press())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: on)
        .accessibilityLabel(subject.name)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

private struct Press: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.96 : 1).animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

private struct PrimaryButton: View {
    let title: String
    let enabled: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(T.serif(19, .semibold)).foregroundStyle(enabled ? T.paper : T.ink2)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 16).fill(enabled ? T.accent : Color(light: 0xCFC6B6, dark: 0x3A342C)))
        }
        .disabled(!enabled)
    }
}
