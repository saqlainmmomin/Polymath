import SwiftUI
import Observation

/// Who the reader is. No account: a first name and a few interests, kept on the device.
@Observable final class Profile {
    private static let nameKey = "profile.name", interestsKey = "profile.interests", doneKey = "profile.onboarded"

    var name: String
    var interests: Set<String>
    var onboarded: Bool

    init() {
        let d = UserDefaults.standard
        if ProcessInfo.processInfo.arguments.contains("--reset-onboarding") {
            [Self.nameKey, Self.interestsKey, Self.doneKey].forEach(d.removeObject(forKey:))
        }
        name = d.string(forKey: Self.nameKey) ?? ""
        interests = Set(d.stringArray(forKey: Self.interestsKey) ?? [])
        onboarded = d.bool(forKey: Self.doneKey)
    }

    func finish(name: String, interests: Set<String>) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.interests = interests
        let d = UserDefaults.standard
        d.set(self.name, forKey: Self.nameKey)
        d.set(Array(interests), forKey: Self.interestsKey)
        d.set(true, forKey: Self.doneKey)
        onboarded = true
    }
}

/// The subjects offered on the interests screen, each with the colour of its blob.
enum Subject {
    static let all: [(name: String, icon: String, color: Color)] = [
        ("Space", "moon.stars", Color(hex: 0x6C5CE7)), ("Biology", "ladybug", Color(hex: 0x3FB37F)), ("Machines", "gearshape.2", Color(hex: 0xE8892B)), ("Nature", "tree", Color(hex: 0x6DBE45)),
        ("Internet", "globe.americas", Color(hex: 0x3F8FE0)), ("Money", "dollarsign.circle", Color(hex: 0xEDB10F)), ("Mind", "brain", Color(hex: 0xE0568B)), ("Physics", "atom", Color(hex: 0x2FB8C9)),
        ("Chemistry", "flask", Color(hex: 0xA2D13F)), ("Earth", "mountain.2", Color(hex: 0xC8643B)), ("History", "building.columns", Color(hex: 0xB08A5A)), ("Music", "music.note", Color(hex: 0xD64545)),
        ("Food", "fork.knife", Color(hex: 0xF2762E)), ("Medicine", "cross.case", Color(hex: 0x4FC3B0)), ("AI", "sparkles", Color(hex: 0x8E6CF0)), ("Security", "lock.shield", Color(hex: 0x4A5FC1)),
        ("Flight", "airplane", Color(hex: 0x5DB4F0)), ("Energy", "bolt", Color(hex: 0xF5C518)), ("Cities", "building.2", Color(hex: 0x8A94A6)), ("Math", "plus.forwardslash.minus", Color(hex: 0xB45CE0)),
        ("Art", "paintpalette", Color(hex: 0xF0507A)), ("Language", "character.bubble", Color(hex: 0x3BA6A0)), ("Law", "scalemass", Color(hex: 0x7A6A55)), ("Sport", "figure.run", Color(hex: 0xE5503C)),
    ]
}

/// Liked and saved topics, by id, kept on the device.
@Observable final class Shelf {
    private static let likedKey = "shelf.liked", savedKey = "shelf.saved"
    private(set) var liked: Set<String>
    private(set) var saved: Set<String>

    init() {
        let d = UserDefaults.standard
        liked = Set(d.stringArray(forKey: Self.likedKey) ?? [])
        saved = Set(d.stringArray(forKey: Self.savedKey) ?? [])
    }

    func toggleLike(_ id: String) { liked.formSymmetricDifference([id]); UserDefaults.standard.set(Array(liked), forKey: Self.likedKey) }
    func toggleSave(_ id: String) { saved.formSymmetricDifference([id]); UserDefaults.standard.set(Array(saved), forKey: Self.savedKey) }
}
