// Theme.swift
// Colours and type for the phone screen. One accent, everything else neutral,
// so the count and the verdicts are what the eye lands on from the floor.

import SwiftUI

enum Theme {
    static let bg = Color(hex: 0x0B0D0E)
    static let surface = Color(hex: 0x15181A)
    static let hairline = Color.white.opacity(0.08)
    static let text = Color(hex: 0xF3F5F6)
    static let muted = Color(hex: 0x8B9297)
    static let faint = Color(hex: 0x4A5156)
    static let accent = Color(hex: 0x3EE6A8)  // chest marker, trace, live
    static let noRep = Color(hex: 0xFF453A)
    static let warn = Color(hex: 0xFFB020)  // rep line, phone moved

    /// Big numbers. DIN Condensed ships with iOS; a missing face falls back to the system font.
    static func display(_ size: CGFloat) -> Font {
        .custom("DINCondensed-Bold", fixedSize: size)
    }

    /// Small labels: upper case, tracked out.
    static func label(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .semibold)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

/// A small upper case caption, the way every label on this screen is set.
struct Caption: View {
    let text: String
    var color: Color = Theme.muted
    var size: CGFloat = 11

    init(_ text: String, color: Color = Theme.muted, size: CGFloat = 11) {
        self.text = text
        self.color = color
        self.size = size
    }

    var body: some View {
        Text(text.uppercased())
            .font(Theme.label(size))
            .tracking(1.6)
            .foregroundStyle(color)
            .lineLimit(1)
    }
}
