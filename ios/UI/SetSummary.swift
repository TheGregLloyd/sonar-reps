// SetSummary.swift
// Shown after Stop: what the set was, rep by rep, and the saved take to share.

import SwiftUI

struct SetSummary: View {
    let reps: [RepEvent]
    let repLineCm: Double
    let duration: TimeInterval
    let fileURL: URL?
    @Environment(\.dismiss) private var dismiss

    private var counted: [RepEvent] { reps.filter(\.valid) }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Caption("Set complete", color: Theme.accent)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.muted)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Theme.surface))
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(counted.count)")
                    .font(Theme.display(120))
                    .monospacedDigit()
                    .foregroundStyle(Theme.text)
                Caption(counted.count == 1 ? "rep" : "reps", size: 14)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 18) {
                Figure(label: "No reps", value: "\(reps.count - counted.count)",
                       color: reps.count > counted.count ? Theme.noRep : Theme.text)
                Figure(label: "Time", value: Self.clock(duration))
                Figure(label: "Deepest", value: depth(counted.map(\.depthCm).max()), unit: "cm")
                Figure(label: "Shallowest", value: depth(counted.map(\.depthCm).min()), unit: "cm")
            }

            VStack(alignment: .leading, spacing: 8) {
                Caption("Depth per movement", size: 10)
                RepHistory(reps: reps, repLineCm: repLineCm)
                    .frame(height: 96)
            }

            Spacer(minLength: 0)

            if let url = fileURL {
                ShareLink(item: url) {
                    Label("Share recording", systemImage: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.text)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.faint, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.bg.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private func depth(_ cm: Double?) -> String {
        cm.map { String(format: "%.1f", $0) } ?? "-"
    }

    static func clock(_ t: TimeInterval) -> String {
        let s = max(0, Int(t))
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

private struct Figure: View {
    let label: String
    let value: String
    var unit: String = ""
    var color: Color = Theme.text

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Caption(label, size: 10)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(Theme.display(36))
                    .monospacedDigit()
                    .foregroundStyle(color)
                if !unit.isEmpty { Caption(unit, size: 10) }
            }
        }
    }
}
