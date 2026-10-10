// SettingsView.swift
// Appearance, the guide, history and About. Tapping the version five times
// turns on developer mode, which holds everything a user never needs: the Mac
// address, the raw recording, and connection details.

import SwiftUI

struct SettingsView: View {
    @ObservedObject var session: SonarSession
    @ObservedObject var log: SetLog
    let showGuide: () -> Void

    @AppStorage("sonarAppearance") private var appearance = Appearance.dark
    @AppStorage("sonarDeveloperMode") private var developerMode = false
    @AppStorage("sonarMacHost") private var macHost = "172.20.10.11"
    @Environment(\.dismiss) private var dismiss
    @State private var versionTaps = 0
    @State private var confirmClear = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Theme.text)
                Spacer()
                Button { dismiss() } label: {
                    Text("Done")
                        .font(.headline)
                        .foregroundStyle(Theme.accent)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    group("Appearance") {
                        HStack(spacing: 8) {
                            AppearanceChoice(title: "Light", symbol: "sun.max", selected: appearance == .light) {
                                appearance = .light
                            }
                            AppearanceChoice(title: "Dark", symbol: "moon", selected: appearance == .dark) {
                                appearance = .dark
                            }
                        }
                        .padding(8)
                    }

                    group("Help") {
                        Row(title: "How it works", symbol: "questionmark.circle") {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { showGuide() }
                        }
                    }

                    group("History") {
                        Row(title: "Clear set history", symbol: "trash", tint: Theme.noRep,
                            detail: log.records.isEmpty ? "Empty" : "\(log.records.count) sets") {
                            confirmClear = true
                        }
                        .disabled(log.records.isEmpty)
                    }

                    group("About") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Counts push-ups with sound you cannot hear. The phone plays three tones near 19 kHz and listens for the echo off your chest. No camera, nothing to wear.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        Divider().overlay(Theme.hairline)
                        Button { tapVersion() } label: {
                            HStack {
                                Text("Version")
                                    .foregroundStyle(Theme.text)
                                Spacer()
                                Text("1.0")
                                    .foregroundStyle(Theme.muted)
                            }
                            .font(.body)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 50)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    if developerMode { developer }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .sonarAppearance()
        .confirmationDialog("Clear all saved sets, including your personal best?",
                            isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear history", role: .destructive) { log.clear() }
        }
    }

    // MARK: Developer

    private var developer: some View {
        group("Developer") {
            VStack(alignment: .leading, spacing: 6) {
                Caption("Mac address", size: 13)
                TextField("172.20.10.11", text: $macHost)
                    .font(.system(size: 16, weight: .medium).monospacedDigit())
                    .foregroundStyle(Theme.text)
                    .textFieldStyle(.plain)
                    .keyboardType(.numbersAndPunctuation)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(16)
            Divider().overlay(Theme.hairline)
            info("Source", session.source == .demo ? "Demo" : "Live")
            Divider().overlay(Theme.hairline)
            info("Status", session.running ? (session.live ? "Receiving" : "Waiting for the Mac") : session.status)
            Divider().overlay(Theme.hairline)
            info("Lost packets", "\(session.lostPackets)")
            Divider().overlay(Theme.hairline)
            info("Rep line", String(format: "%.0f cm", session.repLineCm))
            if let error = session.error {
                Divider().overlay(Theme.hairline)
                Text(error)
                    .font(.system(size: 13).monospaced())
                    .foregroundStyle(Theme.noRep)
                    .padding(16)
            }
            if let url = session.lastFileURL {
                Divider().overlay(Theme.hairline)
                ShareLink(item: url) {
                    HStack {
                        Label("Share last recording", systemImage: "square.and.arrow.up")
                        Spacer()
                    }
                    .font(.body)
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 50)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            Divider().overlay(Theme.hairline)
            Row(title: "Turn off developer mode", symbol: "hammer", tint: Theme.muted) {
                developerMode = false
                versionTaps = 0
            }
        }
    }

    private func tapVersion() {
        guard !developerMode else { return }
        versionTaps += 1
        if versionTaps >= 5 {
            withAnimation(.easeOut(duration: 0.25)) { developerMode = true }
        }
    }

    // MARK: Pieces

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Caption(title, size: 13)
                .padding(.leading, 4)
            VStack(alignment: .leading, spacing: 0, content: content)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.hairline, lineWidth: 1))
        }
    }

    private func info(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Theme.text)
            Spacer()
            Text(value).foregroundStyle(Theme.muted).lineLimit(1)
        }
        .font(.body)
        .padding(.horizontal, 16)
        .frame(minHeight: 50)
    }
}

private struct Row: View {
    let title: String
    let symbol: String
    var tint: Color = Theme.text
    var detail: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .frame(width: 22)
                    .accessibilityHidden(true)
                    .foregroundStyle(tint)
                Text(title)
                    .foregroundStyle(tint)
                Spacer()
                if let detail { Text(detail).foregroundStyle(Theme.muted) }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.faint)
            }
            .font(.body)
            .padding(.horizontal, 16)
            .frame(minHeight: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct AppearanceChoice: View {
    let title: String
    let symbol: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol).font(.system(size: 18))
                Text(title).font(.subheadline)
            }
            .foregroundStyle(selected ? Theme.onAccent : Theme.text)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(RoundedRectangle(cornerRadius: 12).fill(selected ? Theme.accent : Theme.bg))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
