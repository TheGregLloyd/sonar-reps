// MotionHistory.swift
// Keeps the last few seconds of chest depth and the finished movements, for
// the trace and the peak mark. Fed by SonarView; owns no sonar state itself.

import SwiftUI

final class MotionHistory: ObservableObject {
    struct Sample { let t: Date; let depth: Double }
    struct Mark { let t: Date; let valid: Bool }

    static let window: TimeInterval = 12

    private(set) var samples: [Sample] = []
    private(set) var marks: [Mark] = []
    // Deepest point of the movement in progress, 0 when resting at the top.
    @Published private(set) var peakCm = 0.0

    func add(depth: Double, at now: Date = Date()) {
        samples.append(Sample(t: now, depth: max(0, depth)))
        trim(now)
        if depth < 1.5 {
            if peakCm != 0 { peakCm = 0 }
        } else if depth > peakCm {
            peakCm = depth
        }
    }

    func mark(valid: Bool, at now: Date = Date()) {
        marks.append(Mark(t: now, valid: valid))
        trim(now)
    }

    func clear() {
        samples = []
        marks = []
        peakCm = 0
    }

    private func trim(_ now: Date) {
        let cutoff = now.addingTimeInterval(-Self.window)
        if let i = samples.firstIndex(where: { $0.t >= cutoff }), i > 0 { samples.removeFirst(i) }
        marks.removeAll { $0.t < cutoff }
    }
}
