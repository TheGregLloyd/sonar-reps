// TraceView.swift
// The last 12 s of chest depth as a line, newest on the right, with the rep
// line across it and a mark where each movement finished.

import SwiftUI

struct TraceView: View {
    @ObservedObject var history: MotionHistory
    let repLineCm: Double

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                draw(ctx, size: size, now: tl.date)
            }
        }
    }

    private func draw(_ ctx: GraphicsContext, size: CGSize, now: Date) {
        let w = size.width, h = size.height
        let window = MotionHistory.window
        let x = { (t: Date) -> CGFloat in w - CGFloat(now.timeIntervalSince(t) / window) * w }
        let y = { (cm: Double) -> CGFloat in h * 0.22 + CGFloat(min(max(cm, 0), DepthGauge.maxCm) / DepthGauge.maxCm) * h * 0.74 }

        // Top of the movement, for reference.
        var base = Path()
        base.move(to: CGPoint(x: 0, y: y(0)))
        base.addLine(to: CGPoint(x: w, y: y(0)))
        ctx.stroke(base, with: .color(Theme.hairline), lineWidth: 1)

        if repLineCm > 0 {
            var line = Path()
            line.move(to: CGPoint(x: 0, y: y(repLineCm)))
            line.addLine(to: CGPoint(x: w, y: y(repLineCm)))
            ctx.stroke(line, with: .color(Theme.warn.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        }

        let samples = history.samples
        if samples.count > 1 {
            var trace = Path()
            for (i, s) in samples.enumerated() {
                let p = CGPoint(x: x(s.t), y: y(s.depth))
                if i == 0 { trace.move(to: p) } else { trace.addLine(to: p) }
            }
            // Hold the last value up to now, so the line reaches the right edge.
            if let last = samples.last { trace.addLine(to: CGPoint(x: w, y: y(last.depth))) }

            var fill = trace
            fill.addLine(to: CGPoint(x: w, y: y(0)))
            fill.addLine(to: CGPoint(x: x(samples[0].t), y: y(0)))
            fill.closeSubpath()
            ctx.fill(fill, with: .linearGradient(
                Gradient(colors: [Theme.accent.opacity(0.0), Theme.accent.opacity(0.16)]),
                startPoint: CGPoint(x: 0, y: y(0)), endPoint: CGPoint(x: 0, y: h)))
            ctx.stroke(trace, with: .color(Theme.accent),
                       style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }

        for m in history.marks {
            let mx = x(m.t)
            let color = m.valid ? Theme.accent : Theme.noRep
            ctx.fill(Path(CGRect(x: mx - 0.75, y: h * 0.13, width: 1.5, height: h * 0.07)), with: .color(color))
            let label = Text(m.valid ? "REP" : "NO REP")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(color)
            ctx.draw(label, at: CGPoint(x: mx, y: h * 0.06), anchor: .center)
        }
    }
}
