// SonarView.swift
// Root screen. A plain placeholder that shows every number SonarSession
// offers; the designed screen replaces it (see HANDOFF_UI.md).

import SwiftUI

struct SonarView: View {
    @StateObject private var session = SonarSession()
    @AppStorage("sonarMacHost") private var macHost = "172.20.10.11"

    var body: some View {
        VStack(spacing: 20) {
            Text("Sonar Reps").font(.largeTitle.bold())
            Text("\(session.count)")
                .font(.system(size: 140, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text(String(format: "%.1f cm down, rep line %.0f cm", session.depthCm, session.repLineCm))
            Text("NO REPS \(session.noReps)").foregroundStyle(.red)
            if let last = session.reps.last {
                Text(last.valid ? String(format: "Last rep %.1f cm", last.depthCm)
                                : String(format: "NO REP, %@: %.1f cm", last.reason, last.depthCm))
                    .foregroundStyle(last.valid ? Color.primary : Color.red)
            }
            if session.phoneMoving {
                Text("PHONE MOVED, NOT COUNTING").bold().foregroundStyle(.orange)
            }
            if session.source == .live {
                TextField("Mac IP address", text: $macHost)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numbersAndPunctuation)
                    .autocorrectionDisabled()
            }
            HStack {
                Button(session.running ? "Stop" : "Start sonar") {
                    if session.running { session.stop() } else { session.start(macHost: macHost) }
                }
                .buttonStyle(.borderedProminent)
                Button("Reset") { session.reset() }
                    .buttonStyle(.bordered)
                    .disabled(!session.running)
            }
            .controlSize(.large)
            Text(session.running ? (session.live ? "LIVE" : "WAITING FOR THE MAC") : session.status)
                .font(.footnote).foregroundStyle(.secondary)
            if let url = session.lastFileURL, !session.running {
                ShareLink(item: url) { Label("Share last take", systemImage: "square.and.arrow.up") }
            }
            if let error = session.error { Text(error).foregroundStyle(.red).font(.footnote) }
        }
        .padding()
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
    }
}

#Preview {
    SonarView()
}
