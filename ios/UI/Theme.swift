// Theme.swift
// Colours and type for the phone screen, in a light and a dark version.
// Warm neutrals, one ink-blue accent, and two signal colours that only appear
// when they mean something: red for NO REP, ochre for the rep line and warnings.

import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

enum Theme {
    static let bg = Color(light: 0xF4F3EF, dark: 0x161615)
    static let surface = Color(light: 0xFFFFFF, dark: 0x201F1D)
    static let hairline = Color(light: 0xE2E0DA, dark: 0x302F2C)
    static let text = Color(light: 0x1A1A1C, dark: 0xEDECE8)
    static let muted = Color(light: 0x6C6A65, dark: 0x9B9993)
    static let faint = Color(light: 0xA9A69F, dark: 0x5F5E59)
    static let accent = Color(light: 0x2A47C4, dark: 0x8FA3F5)  // chest past the line, trace, counted reps
    static let onAccent = Color(light: 0xFFFFFF, dark: 0x111632)
    static let noRep = Color(light: 0xC33A2E, dark: 0xEE6F63)
    static let warn = Color(light: 0xA86F12, dark: 0xD9A445)  // rep line, phone moved

    // Full-screen verdicts keep one strong colour in both modes, so they read from the floor.
    static let noRepFill = Color(hex: 0xC33A2E)
    static let warnFill = Color(hex: 0xE2A93B)
    static let warnInk = Color(hex: 0x2A1E05)

    /// Big numbers. DIN Condensed ships with iOS; a missing face falls back to the system font.
    static func display(_ size: CGFloat) -> Font {
        .custom("DINCondensed-Bold", fixedSize: size)
    }
}

/// Light or dark, picked by the user and kept across launches.
enum Appearance: String {
    case light, dark
    var scheme: ColorScheme { self == .dark ? .dark : .light }
    var toggled: Appearance { self == .dark ? .light : .dark }
}

private struct SonarAppearance: ViewModifier {
    @AppStorage("sonarAppearance") private var appearance = Appearance.dark
    func body(content: Content) -> some View {
        content.preferredColorScheme(appearance.scheme)
    }
}

extension View {
    /// Applies the user's light or dark choice. Every screen and sheet uses it.
    func sonarAppearance() -> some View { modifier(SonarAppearance()) }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }

    /// A colour that follows the light or dark appearance it is drawn in.
    init(light: UInt32, dark: UInt32) {
        #if canImport(UIKit)
        self.init(UIColor { $0.userInterfaceStyle == .dark ? UIColor(Color(hex: dark)) : UIColor(Color(hex: light)) })
        #else
        self.init(NSColor(name: nil) { a in
            a.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(Color(hex: dark)) : NSColor(Color(hex: light))
        })
        #endif
    }
}

/// A small label, set the same way everywhere on this screen.
struct Caption: View {
    let text: String
    var color: Color = Theme.muted
    var size: CGFloat = 12

    init(_ text: String, color: Color = Theme.muted, size: CGFloat = 12) {
        self.text = text
        self.color = color
        self.size = size
    }

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(color)
            .lineLimit(1)
    }
}
