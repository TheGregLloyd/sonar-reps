// Brand.swift
// The Sonar Reps mark: a phone lying flat with three echo arcs rising from it.
// Drawn in code so it stays sharp at any size; the app icon is rendered from it.

import SwiftUI

struct LogoMark: View {
    var color: Color = Theme.accent

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width, size.height)
            let cx = size.width / 2
            let baseY = size.height / 2 + s * 0.28
            let line = max(1.5, s * 0.075)

            // Arcs, nearest first, fading as they spread.
            for i in 0..<3 {
                let r = s * (0.17 + Double(i) * 0.15)
                var arc = Path()
                arc.addArc(center: CGPoint(x: cx, y: baseY - s * 0.06), radius: r,
                           startAngle: .degrees(215), endAngle: .degrees(325), clockwise: false)
                ctx.stroke(arc, with: .color(color.opacity(1 - Double(i) * 0.28)),
                           style: StrokeStyle(lineWidth: line, lineCap: .round))
            }

            // The phone, side on.
            let phone = CGRect(x: cx - s * 0.3, y: baseY, width: s * 0.6, height: s * 0.1)
            ctx.fill(Path(roundedRect: phone, cornerRadius: s * 0.05), with: .color(color))
        }
    }
}

/// The app icon artwork, 1024 points square. Rendered once to AppIcon.png.
struct AppIconArt: View {
    var body: some View {
        ZStack {
            Theme.bg
            LogoMark()
                .padding(170)
        }
        .frame(width: 1024, height: 1024)
    }
}
