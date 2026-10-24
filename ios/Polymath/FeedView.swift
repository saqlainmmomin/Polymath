import SwiftUI

/// The shorts feed: swipe up for the next topic (vertical paging); each topic is a horizontal row of cards.
struct FeedView: View {
    @Environment(Store.self) private var store
    @State private var current: String?
    @State private var showIndex = Launch.showIndex

    var body: some View {
        // The pager fills the whole screen (so one page is exactly one screen and the next topic never peeks in under the home indicator);
        // each topic pads itself by the real safe-area insets, read here before they are ignored.
        GeometryReader { geo in
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(store.topics) { t in
                        TopicView(topic: t, isCurrent: current == t.id,
                                  openIndex: { showIndex = true },
                                  jump: { id in withAnimation(.easeInOut(duration: 0.35)) { current = id } })
                            .padding(.top, geo.safeAreaInsets.top)
                            .padding(.bottom, geo.safeAreaInsets.bottom)
                            .containerRelativeFrame([.horizontal, .vertical])
                            .id(t.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $current)
            .scrollIndicators(.hidden)
            .ignoresSafeArea()
        }
        .background(T.paper.ignoresSafeArea())
        .onAppear { if current == nil { current = store.topics.first?.id } }
        .sheet(isPresented: $showIndex) {
            IndexView { id in showIndex = false; withAnimation { current = id } }
                .presentationDetents([.large])
        }
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
