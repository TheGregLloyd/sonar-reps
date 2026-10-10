// SonarView.swift
// Minimal screen to drive SonarEngine: type the Mac's IP, press Start,
// put the phone face-up on the floor under your chest.

import SwiftUI

struct SonarView: View {
    @StateObject private var sonar = SonarEngine()
    @AppStorage("sonarMacHost") private var macHost = "172.20.10.2"
    @State private var error: String?

    var body: some View {
        VStack(spacing: 24) {
            Text("Sonar Reps").font(.largeTitle.bold())
            TextField("Mac IP address", text: $macHost)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numbersAndPunctuation)
                .autocorrectionDisabled()
            Button(sonar.running ? "Stop" : "Start sonar") {
                if sonar.running {
                    sonar.stop()
                } else {
                    do { try sonar.start(macHost: macHost) } catch { self.error = error.localizedDescription }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Text(sonar.status).font(.footnote).foregroundStyle(.secondary)
            if let url = sonar.lastFileURL, !sonar.running {
                ShareLink(item: url) { Label("Share last take", systemImage: "square.and.arrow.up") }
            }
            if let error { Text(error).foregroundStyle(.red).font(.footnote) }
        }
        .padding()
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
    }
}
