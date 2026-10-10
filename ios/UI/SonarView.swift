// SonarView.swift
// Root screen. Before a set: one Start button. During a set the phone lies
// under the chest and nothing needs a touch: the count, the depth column, the
// rep history and the trace all read from 30 to 60 cm away.
// No sound and no haptics anywhere: the speaker is the sonar, and a vibration
// would trip the motion check and block counting.

import SwiftUI

struct SonarView: View {
    @StateObject private var session = SonarSession()
    @StateObject private var history = MotionHistory()
    @AppStorage("sonarMacHost") private var macHost = "172.20.10.11"

    @State private var countScale: CGFloat = 1
    @State private var hit = false
    @State private var noRepDetail: String?
    @State private var noRepToken = 0
    @AppStorage("sonarSeenIntro") private var seenIntro = false
    @State private var showIntro = false
    @State private var showSummary = false
    @State private var setStart = Date()
    @State private var setDuration: TimeInterval = 0

    var body: some View {
        ZStack(alignment: .top) {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 16) {
                header
                VStack(spacing: 16) {
                    readout
                    section("Set") { RepHistory(reps: session.reps, repLineCm: session.repLineCm) }
                        .frame(height: 78)
                    section("Chest movement, last 12 s") { TraceView(history: history, repLineCm: session.repLineCm) }
                        .frame(height: 104)
                }
                .grayscale(session.phoneMoving ? 1 : 0)
                .opacity(session.phoneMoving ? 0.4 : 1)
                .animation(.easeOut(duration: 0.18), value: session.phoneMoving)
                controls
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)

            if session.phoneMoving {
                PhoneMovedBanner()
                    .padding(.top, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if let detail = noRepDetail {
                NoRepOverlay(detail: detail)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.18), value: session.phoneMoving)
        .preferredColorScheme(.dark)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            if !seenIntro { showIntro = true }
        }
        .sheet(isPresented: $showIntro, onDismiss: { seenIntro = true }) { HowItWorks() }
        .sheet(isPresented: $showSummary) {
            SetSummary(reps: session.reps, repLineCm: session.repLineCm,
                       duration: setDuration, fileURL: session.lastFileURL)
        }
        .onChange(of: session.depthCm) { history.add(depth: session.depthCm) }
        .onChange(of: session.reps.count) { old, new in
            if new == 0 { history.clear() }
            guard new > old, let rep = session.reps.last else { return }
            history.mark(valid: rep.valid)
            if rep.valid { celebrate() } else { refuse(rep) }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 10) {
                LogoMark().frame(width: 26, height: 26)
                Text("SONAR REPS")
                    .font(Theme.display(24))
                    .tracking(3)
                    .foregroundStyle(Theme.text)
                Spacer()
                if session.running {
                    TimelineView(.periodic(from: setStart, by: 1)) { tl in
                        Text(SetSummary.clock(tl.date.timeIntervalSince(setStart)))
                            .font(.system(size: 13, weight: .semibold).monospacedDigit())
                            .foregroundStyle(Theme.muted)
                    }
                } else {
                    Button { showIntro = true } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 17))
                            .foregroundStyle(Theme.muted)
                    }
                    .buttonStyle(.plain)
                }
                StatusPill(state: pillState)
            }
            Text("No camera. Three tones near 19 kHz, echoing off your chest.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
                .lineLimit(2)
        }
    }

    private var pillState: StatusPill.State {
        if !session.running { return session.source == .demo ? .demo : .ready }
        return session.live ? .live : .waiting
    }

    // MARK: Count and depth

    private var readout: some View {
        GeometryReader { geo in
            let gaugeWidth = min(150, geo.size.width * 0.36)
            let countWidth = geo.size.width - gaugeWidth - 16
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 0) {
                    Caption("Reps")
                    Spacer(minLength: 0)
                    Text("\(session.count)")
                        .font(Theme.display(min(countWidth * 1.45, geo.size.height * 0.72)))
                        .monospacedDigit()
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                        .scaleEffect(countScale, anchor: .bottomLeading)
                    Spacer(minLength: 0)
                    HStack(alignment: .top, spacing: 22) {
                        Stat(label: "No reps", value: "\(session.noReps)",
                             color: session.noReps > 0 ? Theme.noRep : Theme.text)
                        Stat(label: "Last depth", value: lastDepth, unit: "cm")
                    }
                }
                .frame(width: countWidth, alignment: .leading)

                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", max(0, session.depthCm)))
                            .font(Theme.display(28))
                            .monospacedDigit()
                            .foregroundStyle(Theme.text)
                        Caption("cm down", size: 9)
                    }
                    DepthGauge(depthCm: session.depthCm, repLineCm: session.repLineCm,
                               peakCm: history.peakCm, live: session.running && session.live,
                               waiting: session.running && !session.live, hit: hit)
                }
                .frame(width: gaugeWidth)
            }
        }
    }

    private var lastDepth: String {
        guard let last = session.reps.last else { return "0.0" }
        return String(format: "%.1f", last.depthCm)
    }

    // MARK: Controls

    @ViewBuilder
    private var controls: some View {
        if session.running {
            HStack(spacing: 10) {
                SmallButton(title: "Stop") { stopSet() }
                SmallButton(title: "Reset") {
                    session.reset()
                    setStart = Date()
                }
                Spacer()
                if session.lostPackets > 0 { Caption("Lost \(session.lostPackets)", color: Theme.faint, size: 10) }
            }
            .frame(height: 40)
        } else {
            VStack(spacing: 12) {
                if session.source == .live {
                    HStack(spacing: 12) {
                        Caption("Mac address", size: 10)
                        TextField("172.20.10.11", text: $macHost)
                            .font(.system(size: 15, weight: .medium).monospacedDigit())
                            .foregroundStyle(Theme.text)
                            .textFieldStyle(.plain)
                            .keyboardType(.numbersAndPunctuation)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
                }

                Button {
                    history.clear()
                    setStart = Date()
                    session.start(macHost: macHost)
                } label: {
                    Text("START SET")
                        .font(Theme.display(24))
                        .tracking(2)
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.accent))
                }
                .buttonStyle(.plain)

                HStack {
                    Text(summary)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    if let url = session.lastFileURL {
                        ShareLink(item: url) {
                            Label("Share take", systemImage: "square.and.arrow.up")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.accent)
                        }
                    }
                }
                if let error = session.error {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.noRep)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    /// Before the first set, how to use it. After a set, what happened.
    private var summary: String {
        let counted = session.reps.filter(\.valid)
        guard !session.reps.isEmpty else {
            return "Phone face-up under your chest. Press start, then hands off."
        }
        var s = "Last set: \(counted.count) reps, \(session.noReps) no rep\(session.noReps == 1 ? "" : "s")"
        if let deep = counted.map(\.depthCm).max(), let shallow = counted.map(\.depthCm).min() {
            s += String(format: ", %.0f to %.0f cm", shallow, deep)
        }
        return s + "."
    }

    private func stopSet() {
        setDuration = Date().timeIntervalSince(setStart)
        session.stop()
        if !session.reps.isEmpty { showSummary = true }
    }

    // MARK: Verdicts

    private func celebrate() {
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) {
            countScale = 1.14
            hit = true
        }
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) { countScale = 1 }
            withAnimation(.easeOut(duration: 0.5)) { hit = false }
        }
    }

    private func refuse(_ rep: RepEvent) {
        let reason = rep.reason.isEmpty ? "not counted" : rep.reason
        var detail = String(format: "%@: %.1f cm", reason, rep.depthCm)
        if session.repLineCm > 0 { detail += String(format: " of %.0f", session.repLineCm) }
        noRepToken += 1
        let token = noRepToken
        withAnimation(.easeOut(duration: 0.08)) { noRepDetail = detail }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            guard token == noRepToken else { return }
            withAnimation(.easeIn(duration: 0.3)) { noRepDetail = nil }
        }
    }

    // MARK: Pieces

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Caption(title, size: 10)
            content()
        }
        .padding(.top, 12)
        .overlay(alignment: .top) { Rectangle().fill(Theme.hairline).frame(height: 1) }
    }
}

private struct Stat: View {
    let label: String
    let value: String
    var unit: String = ""
    var color: Color = Theme.text

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Caption(label, size: 10)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(Theme.display(34))
                    .monospacedDigit()
                    .foregroundStyle(color)
                if !unit.isEmpty { Caption(unit, size: 10) }
            }
        }
    }
}

private struct SmallButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(Theme.muted)
                .padding(.horizontal, 16)
                .frame(height: 36)
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.faint, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct StatusPill: View {
    enum State { case ready, demo, live, waiting }
    let state: State
    @SwiftUI.State private var blink = false

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
                .opacity(state == .live && blink ? 0.25 : 1)
            Caption(title, color: color, size: 10)
        }
        .padding(.horizontal, 10)
        .frame(height: 24)
        .overlay(Capsule().strokeBorder(color.opacity(0.5), lineWidth: 1))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.55).repeatForever()) { blink = true }
        }
    }

    private var title: String {
        switch state {
        case .ready: return "Ready"
        case .demo: return "Demo"
        case .live: return "Live"
        case .waiting: return "Waiting"
        }
    }

    private var color: Color {
        switch state {
        case .live: return Theme.accent
        case .waiting: return Theme.warn
        case .ready, .demo: return Theme.muted
        }
    }
}

#Preview {
    SonarView()
}
