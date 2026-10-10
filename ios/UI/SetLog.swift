// SetLog.swift
// Every finished set, kept on the phone: when it was, how many reps, how deep.
// The personal best is worked out from it. Stored as JSON in UserDefaults.

import Foundation

struct SetRecord: Codable, Identifiable, Equatable {
    var id = UUID()
    let date: Date
    let reps: Int
    let noReps: Int
    let duration: TimeInterval
    let depths: [Double]  // every counted rep, in order

    var deepest: Double? { depths.max() }
    var average: Double? { depths.isEmpty ? nil : depths.reduce(0, +) / Double(depths.count) }

    /// More reps wins; on a tie, the deeper average.
    func beats(_ other: SetRecord) -> Bool {
        if reps != other.reps { return reps > other.reps }
        return (average ?? 0) > (other.average ?? 0)
    }
}

final class SetLog: ObservableObject {
    @Published private(set) var records: [SetRecord] = []  // newest first

    private static let key = "sonarSetLog"
    private static let keep = 100

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode([SetRecord].self, from: data) {
            records = saved
        }
    }

    var best: SetRecord? {
        records.filter { $0.reps > 0 }.reduce(nil) { best, r in
            guard let b = best else { return r }
            return r.beats(b) ? r : b
        }
    }

    func clear() {
        records = []
        UserDefaults.standard.removeObject(forKey: Self.key)
    }

    /// Saves the set and says whether it is a new personal best.
    @discardableResult
    func add(_ record: SetRecord) -> Bool {
        let previous = best
        records.insert(record, at: 0)
        if records.count > Self.keep { records.removeLast(records.count - Self.keep) }
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
        guard record.reps > 0 else { return false }
        return previous.map { record.beats($0) } ?? true
    }
}

func clockText(_ t: TimeInterval) -> String {
    let s = max(0, Int(t))
    return String(format: "%d:%02d", s / 60, s % 60)
}

func depthText(_ cm: Double?) -> String {
    cm.map { String(format: "%.1f", $0) } ?? "-"
}

extension Date {
    /// "Sat 10 Oct, 14:02"
    var setStamp: String {
        formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())
    }
}
