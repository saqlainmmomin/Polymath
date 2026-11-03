import SwiftUI

/// Dev preview (`--preview --topic <id> --card <n>`): one picture the way the Narrated screen plays it, on the topic's own backdrop, under its
/// title, with no caption or player. It runs on the narration's clock with no voice behind it (plays once, holds, then starts over), so it shows the final look.
/// Tap the picture for the next card.
struct PicturePreview: View {
    let topic: Topic
    let isCurrent: Bool
    @State private var start = Date()
    @State private var card = Launch.card ?? 0     // tap the picture to go to the next one
    private static let loop = 9.0     // the picture's story, a hold, then again

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 42)   // under the feed's logo and avatar
            Text(topic.title)               // as on the Narrated screen
                .font(S.rounded(24, .bold)).lineSpacing(2).foregroundStyle(S.text)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 21).padding(.top, 16)
            TimelineView(.animation(paused: !isCurrent)) { tl in
                let t = tl.date.timeIntervalSince(start).truncatingRemainder(dividingBy: Self.loop)
                Pictures.view(topic: topic, index: card, active: isCurrent)
                    .environment(\.pictureClock, PictureClock(t: t, clock: t))
                    .environment(\.stage, topic.look.stage)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                Color.clear.contentShape(Rectangle()).onTapGesture {
                    card = (card + 1) % max(1, topic.contentCardCount)
                    start = Date()
                }
            }
            .padding(.horizontal, 8).padding(.bottom, 24)
        }
    }
}
