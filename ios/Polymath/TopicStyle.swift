import SwiftUI

/// The look a topic is drawn in (owner, 2026-11-02). Each style is its own illustrator with its own drawing kit, and it sets the whole
/// screen: backdrop, light or dark text, status bar and the pictures' palette. One per topic, from `"style"` in its JSON; blueprint if absent.
enum TopicStyle: String, Decodable {
    case blueprint      // navy paper with a grid, thin white isometric line art (Blueprint.swift)
    case drafting       // plain white, realistic line art in crisp black, hatching, one yellow accent (Drafting.swift)
    case wireframe      // black, fine white wireframe meshes in 3D, lowercase mono labels, one pastel pink accent (Wireframe.swift)
    case airbrush       // photo-of-paper backdrop, thin black line, sprayed colour clouds and soft airbrushed glows, green condensed labels (Airbrush.swift)

    /// Light or dark screen: decides text, buttons and the status bar.
    var scheme: ColorScheme { self == .drafting || self == .airbrush ? .light : .dark }

    /// The flat colour under everything, also used where a whole backdrop is too much (profile thumbnails).
    var base: Color {
        switch self {
        case .blueprint: BP.paper
        case .drafting: DR.paper
        case .wireframe: WF.paper
        case .airbrush: AB.paper
        }
    }

    /// What fills the screen behind a topic.
    @ViewBuilder var backdrop: some View {
        switch self {
        case .blueprint: PaperGrid()
        case .drafting: DR.paper.ignoresSafeArea()
        case .wireframe: WF.paper.ignoresSafeArea()
        case .airbrush: PaperTexture()
        }
    }

    /// Line colour, a quieter one and the accent, for pictures drawn in this style.
    var stage: StagePalette {
        switch self {
        case .blueprint: S.stage(S.paper)
        case .drafting: StagePalette(ink: DR.ink, soft: DR.ink.opacity(0.45), accent: DR.accent)
        case .wireframe: StagePalette(ink: WF.ink, soft: WF.ink.opacity(0.4), accent: WF.accent)
        case .airbrush: StagePalette(ink: AB.ink, soft: AB.ink.opacity(0.4), accent: AB.yellow)
        }
    }
}

extension Topic {
    /// This topic's style; blueprint when its file names none.
    var look: TopicStyle { style ?? .blueprint }
}
