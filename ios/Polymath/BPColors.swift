import SwiftUI

// Shared picture hues for Blueprint pictures ("Macaron" palette, owner's pick 2026-11-02): chalk linework stays the base, and these flat soft colours
// mark meaning, sparingly: mustard is the one focal thing on a card, and at most two other hues join it. Same thing, same hue, on every card of a
// topic. Flat fills only: no gradients, glow or blur.
extension BP {
    enum Hue {
        static let mustard = Color(hex: 0xF2C14E)   // the one thing the card is about (same as the stage accent)
        static let ice = Color(hex: 0xF2F6FF)       // water, air, sound, signals, information (reads almost as chalk)
        static let coral = Color(hex: 0xFF6F61)     // warm: heat, force, energy, the Sun and Moon
        static let peach = Color(hex: 0xFFB89A)     // the stuff things are made of or travel through: glue, ground, hills, readers
        static let pistachio = Color(hex: 0xA8E6CF) // living and receiving: people, eyes, receivers, "arrived"
    }
}
