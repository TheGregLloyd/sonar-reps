// RepHistory.swift
// One bar per finished movement, height by depth, so a set's shape (and any
// fade at the end) reads at a glance. NO REP bars are red.

import SwiftUI

struct RepHistory: View {
    let reps: [RepEvent]
    let repLineCm: Double

    private static let shown = 12

    var body: some View {
        let recent = Array(reps.suffix(Self.shown))
        let scale = max(recent.map(\.depthCm).max() ?? 0, repLineCm * 1.4, 10)

        GeometryReader { geo in
            let barArea = geo.size.height - 16
            ZStack(alignment: .bottomLeading) {
                if recent.isEmpty {
                    Caption("Reps appear here", color: Theme.faint, size: 10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if repLineCm > 0 {
                    Path { p in
                        let ly = barArea - CGFloat(repLineCm / scale) * barArea
                        p.move(to: CGPoint(x: 0, y: ly))
                        p.addLine(to: CGPoint(x: geo.size.width, y: ly))
                    }
                    .stroke(Theme.warn.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }

                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(recent) { rep in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(rep.valid ? Theme.accent : Theme.noRep)
                                .frame(height: max(3, CGFloat(min(rep.depthCm, scale) / scale) * barArea))
                            Text("\(Int(rep.depthCm.rounded()))")
                                .font(.system(size: 10, weight: .semibold).monospacedDigit())
                                .foregroundStyle(rep.valid ? Theme.muted : Theme.noRep)
                                .frame(height: 12)
                        }
                        .frame(maxWidth: 26)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.easeOut(duration: 0.35), value: reps.count)
            }
        }
    }
}
