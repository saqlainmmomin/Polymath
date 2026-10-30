import SwiftUI

/// The shorts feed: any upward swipe anywhere on the page goes to the next topic, downward to the previous one.
/// Not a vertical ScrollView: its pan lost to the card pager and to pictures mid-animation. One drag watched alongside
/// every child gesture decides instead: the page follows the finger once the drag is mostly vertical, and a short flick is enough.
struct FeedView: View {
    @Environment(Store.self) private var store
    @Environment(Profile.self) private var profile
    @State private var index = 0
    @State private var drag: CGFloat = 0
    @State private var axis: Axis?
    @State private var showIndex = Launch.showIndex
    @State private var showProfile = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        // Each topic fills the whole screen and pads itself by the real safe-area insets, read here before they are ignored.
        GeometryReader { geo in
            let h = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
            ZStack {
                ForEach(window, id: \.offset) { i, t in
                    Group {
                        if let v = Narration.load(t.id) { VoiceTopicView(topic: t, narration: v.0, audio: v.1, isCurrent: i == index) }
                        else { TopicView(topic: t, isCurrent: i == index, jump: go(to:)) }
                    }
                        .environment(\.colorScheme, store.isPaper(t) ? .dark : scheme)   // blueprint paper is always blue, so its text is light
                        .padding(.top, geo.safeAreaInsets.top)
                        .padding(.bottom, geo.safeAreaInsets.bottom)
                        .frame(width: geo.size.width, height: h)
                        .background { if store.isPaper(t) { PaperGrid() } }
                        .background(S.background(store.shade(t)))
                        .offset(y: CGFloat(i - index) * h + drag)
                }
            }
            .frame(width: geo.size.width, height: h, alignment: .top)
            .clipped()
            .contentShape(Rectangle())
            .simultaneousGesture(swipe(height: h))
            .ignoresSafeArea()
        }
        .overlay(alignment: .topTrailing) {
            // Fixed to the screen, above every topic, so it doesn't slide away with a swipe.
            Avatar(name: profile.name) { showProfile = true }.padding(.trailing, 16).padding(.top, 2)
        }
        .background(S.background(store.topics.indices.contains(index) ? store.shade(store.topics[index]) : 0).ignoresSafeArea())
        .preferredColorScheme(store.topics.indices.contains(index) && store.isPaper(store.topics[index]) ? .dark : nil)   // status bar and avatar match the blue
        .sheet(isPresented: $showIndex) {
            IndexView { id in showIndex = false; go(to: id) }
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showProfile) {
            ProfileView { id in showProfile = false; go(to: id) }
                .presentationDetents([.medium, .large])
        }
    }

    /// The current topic and its neighbours: the only ones built, so a swipe always has a page to reveal.
    private var window: [(offset: Int, element: Topic)] {
        let all = Array(store.topics.enumerated())
        return Array(all[max(0, index - 1)...min(all.count - 1, index + 1)])
    }

    private func swipe(height h: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { v in
                if axis == nil { axis = abs(v.translation.height) > abs(v.translation.width) ? .vertical : .horizontal }
                guard axis == .vertical else { return }
                let atEnd = (v.translation.height < 0 && index == store.topics.count - 1) || (v.translation.height > 0 && index == 0)
                drag = v.translation.height * (atEnd ? 0.25 : 1)   // rubber band past the first and last topic
            }
            .onEnded { v in
                defer { axis = nil }
                guard axis == .vertical else { return }
                let dy = v.translation.height, fling = v.predictedEndTranslation.height
                var next = index
                if dy < -40 || fling < -h * 0.25 { next = min(index + 1, store.topics.count - 1) }
                else if dy > 40 || fling > h * 0.25 { next = max(index - 1, 0) }
                if next != index { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
                // Keep the page where the finger left it, then spring to the new slot.
                drag += CGFloat(next - index) * h
                index = next
                withAnimation(.spring(response: 0.38, dampingFraction: 0.9)) { drag = 0 }
            }
    }

    private func go(to id: String) {
        guard let i = store.topics.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.easeInOut(duration: 0.35)) { index = i }
    }
}

/// Plain list of every topic: question and card count.
struct IndexView: View {
    @Environment(Store.self) private var store
    let pick: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Index").monoLabel().foregroundStyle(T.ink2).padding(.top, 22).padding(.bottom, 8)
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(store.topics) { t in
                        Button { pick(t.id) } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 14) {
                                Text(t.title).font(T.serif(20, .medium)).foregroundStyle(T.ink).multilineTextAlignment(.leading)
                                Spacer(minLength: 8)
                                Text("\(t.cards.count) cards").monoLabel().foregroundStyle(T.ink2)
                            }
                            .padding(.vertical, 16)
                            .overlay(alignment: .top) { Rectangle().fill(T.rule).frame(height: 1) }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .background(T.paper.ignoresSafeArea())
    }
}

/// Opened from the avatar: who you are, what you picked, and the topics you saved, then every topic.
struct ProfileView: View {
    @Environment(Store.self) private var store
    @Environment(Profile.self) private var profile
    @Environment(Shelf.self) private var shelf
    let pick: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 14) {
                    Text(profile.name.first.map { String($0).uppercased() } ?? "?")
                        .font(S.rounded(24, .semibold)).foregroundStyle(S.text)
                        .frame(width: 56, height: 56).background(Circle().fill(S.line))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.name.isEmpty ? "You" : profile.name).font(S.rounded(22, .medium)).foregroundStyle(S.text)
                        Text("Kept on this phone").font(S.rounded(14)).foregroundStyle(S.text2)
                    }
                }
                .padding(.top, 28)

                if !profile.interests.isEmpty {
                    heading("Interests")
                    Text(profile.interests.sorted().joined(separator: " · ")).font(S.rounded(16)).foregroundStyle(S.text)
                }

                heading("Saved")
                let saved = store.topics.filter { shelf.saved.contains($0.id) }
                if saved.isEmpty {
                    Text("Tap the bookmark on a topic to keep it here.").font(S.rounded(16)).foregroundStyle(S.text2)
                } else {
                    rows(saved)
                }

                heading("All topics")
                rows(store.topics)
            }
            .padding(.horizontal, 21).padding(.bottom, 24)
        }
        .background(Color(light: 0xFFFFFF, dark: 0x09090B).ignoresSafeArea())
    }

    private func heading(_ t: String) -> some View {
        Text(t).font(S.rounded(13, .semibold)).foregroundStyle(S.faint).padding(.top, 28).padding(.bottom, 8)
    }

    private func rows(_ topics: [Topic]) -> some View {
        VStack(spacing: 0) {
            ForEach(topics) { t in
                Button { pick(t.id) } label: {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous).fill(S.background(store.shade(t))).frame(width: 28, height: 28)
                        Text(t.title).font(S.rounded(16, .medium)).foregroundStyle(S.text).multilineTextAlignment(.leading)
                        Spacer(minLength: 8)
                        if shelf.liked.contains(t.id) { Image(systemName: "heart.fill").font(.system(size: 13)).foregroundStyle(Color(hex: 0xF43F5E)) }
                    }
                    .padding(.vertical, 12)
                    .overlay(alignment: .top) { Rectangle().fill(S.line).frame(height: 1) }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
