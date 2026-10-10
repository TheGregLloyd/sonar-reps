// DepthGauge.swift
// The column: 0 cm at the top (arms straight) to 40 cm at the bottom, where
// the phone lies. A bar marks the chest, a dashed line marks the depth a rep
// must reach, and faint arcs rise from the phone while the sonar is live.

import SwiftUI

struct DepthGauge: View {
    let depthCm: Double
    let repLineCm: Double
    let peakCm: Double
    let live: Bool
    let waiting: Bool
    let hit: Bool  // a rep just counted

    static let maxCm = 40.0

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width
            let top = h * 0.05
            let usable = h * 0.76
            let y = { (cm: Double) -> CGFloat in top + CGFloat(min(max(cm, 0), Self.maxCm) / Self.maxCm) * usable }
            let deep = repLineCm > 0 && depthCm >= repLineCm
            let barColor = deep ? Theme.warn : Theme.accent

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14).fill(Theme.surface)
                RoundedRectangle(cornerRadius: 14).fill(Theme.accent.opacity(hit ? 0.16 : 0))

                // Scale: a tick every 5 cm, a number every 10.
                Canvas { ctx, _ in
                    for i in 0...8 {
                        let cm = Double(i) * 5
                        let major = i % 2 == 0
                        let ty = y(cm)
                        var tick = Path()
                        tick.move(to: CGPoint(x: 0, y: ty))
                        tick.addLine(to: CGPoint(x: major ? 12 : 7, y: ty))
                        ctx.stroke(tick, with: .color(major ? Theme.faint : Theme.faint.opacity(0.5)), lineWidth: 1)
                        if major {
                            let label = Text("\(Int(cm))")
                                .font(.system(size: 10, weight: .medium).monospacedDigit())
                                .foregroundColor(Theme.faint)
                            ctx.draw(label, at: CGPoint(x: 17, y: ty), anchor: .leading)
                        }
                    }
                }

                if repLineCm > 0 {
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: y(repLineCm)))
                        p.addLine(to: CGPoint(x: w, y: y(repLineCm)))
                    }
                    .stroke(Theme.warn.opacity(0.85), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    Caption("Rep line \(Int(repLineCm.rounded())) cm", color: Theme.warn, size: 9)
                        .position(x: w / 2, y: y(repLineCm) + 11)
                }

                if peakCm > 3 {
                    Rectangle().fill(Theme.text.opacity(0.45))
                        .frame(width: w * 0.5, height: 1.5)
                        .position(x: w / 2 + 8, y: y(peakCm))
                }

                // The chest.
                Capsule().fill(barColor)
                    .frame(width: w * 0.62, height: 8)
                    .position(x: w / 2 + 8, y: y(depthCm))
                    .animation(.easeOut(duration: 0.12), value: depthCm)

                if live {
                    SonarPings()
                        .frame(width: w, height: h * 0.34)
                        .position(x: w / 2, y: h - 22 - h * 0.17)
                        .allowsHitTesting(false)
                }

                PhoneGlyph()
                    .frame(width: min(w * 0.46, 56), height: 9)
                    .position(x: w / 2, y: h - 22)

                if waiting {
                    WaitingText()
                        .frame(width: w, height: h)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

/// The phone, face-up, seen side on.
private struct PhoneGlyph: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .stroke(Theme.muted, lineWidth: 1.5)
            .background(RoundedRectangle(cornerRadius: 3).fill(Theme.bg))
    }
}

/// Three thin arcs spreading up from the phone: one every 0.7 s, each lasting 2.1 s.
private struct SonarPings: View {
    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate
                let base = CGPoint(x: size.width / 2, y: size.height)
                for i in 0..<3 {
                    let phase = ((t + Double(i) * 0.7).truncatingRemainder(dividingBy: 2.1)) / 2.1
                    let r = 8 + phase * Double(size.height - 8)
                    var arc = Path()
                    arc.addArc(center: base, radius: r, startAngle: .degrees(205), endAngle: .degrees(335), clockwise: false)
                    ctx.stroke(arc, with: .color(Theme.accent.opacity(0.45 * (1 - phase))), lineWidth: 1.2)
                }
            }
        }
    }
}

private struct WaitingText: View {
    @State private var dim = false
    var body: some View {
        VStack(spacing: 6) {
            Caption("Waiting for", size: 10)
            Caption("sonar stream", size: 10)
        }
        .opacity(dim ? 0.3 : 1)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever()) { dim = true }
        }
    }
}
