import SwiftUI

/// The shorts feed: a native paging scroll, as on Reels and Shorts, one topic per screen (owner, 2026-11-03: the hand-rolled
/// drag stuttered, since every frame of a swipe rebuilt the pages). The old reason for avoiding a ScrollView, its pan losing
/// to the Cards pager, is gone: the feed shows Narrated topics only, which have no sideways swipe.
struct FeedView: View {
    @Environment(Store.self) private var store
    @Environment(Profile.self) private var profile
    @State private var index = 0
    @State private var position: Int? = 0
    @State private var showIndex = Launch.showIndex
    @State private var showProfile = false

    var body: some View {
        // Each topic fills the whole screen and pads itself by the real safe-area insets, read here before they are ignored.
        GeometryReader { geo in
            let h = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(store.topics.enumerated()), id: \.element.id) { i, t in
                        Group {
                            if let v = Narration.load(t.id) { VoiceTopicView(topic: t, narration: v.0, audio: v.1, isCurrent: i == index) }
                            else if Launch.preview { PicturePreview(topic: t, isCurrent: i == index) }
                            else { TopicView(topic: t, isCurrent: i == index, jump: go(to:)) }
                        }
                            .environment(\.colorScheme, t.look.scheme)   // the topic's style decides light or dark, not the phone's setting
                            .padding(.top, geo.safeAreaInsets.top)
                            .padding(.bottom, geo.safeAreaInsets.bottom)
                            .frame(width: geo.size.width, height: h)
                            .background { t.look.backdrop }
                            .id(i)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $position)
            .scrollIndicators(.hidden)
            .ignoresSafeArea()
            .onChange(of: position) { _, p in if let p { index = p } }
        }
        .overlay(alignment: .top) {
            // Fixed to the screen, above every topic, so they don't slide away with a swipe.
            HStack(spacing: 10) {
                Logo().frame(width: 32, height: 32)
                Spacer()
                Avatar(name: profile.name) { showProfile = true }
            }
            .padding(.horizontal, 16).padding(.top, 2)
        }
        .background((store.topics.indices.contains(index) ? store.topics[index].look : .blueprint).base.ignoresSafeArea())
        .preferredColorScheme(store.topics.indices.contains(index) ? store.topics[index].look.scheme : nil)   // status bar, logo and avatar match the current topic's style
        .sheet(isPresented: $showIndex) {
            IndexView { id in showIndex = false; go(to: id) }
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showProfile) {
            ProfileView { id in showProfile = false; go(to: id) }
                .presentationDetents([.medium, .large])
        }
    }

    private func go(to id: String) {
        guard let i = store.topics.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.easeInOut(duration: 0.35)) { position = i }
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
                        RoundedRectangle(cornerRadius: 8, style: .continuous).fill(t.look.base).frame(width: 28, height: 28)
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
