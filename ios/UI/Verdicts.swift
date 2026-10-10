// Verdicts.swift
// The two states that must read from a metre away mid push-up:
// a refused movement (full-screen red) and the phone itself moving (amber banner).

import SwiftUI

struct NoRepOverlay: View {
    let detail: String

    var body: some View {
        ZStack {
            Theme.noRep.ignoresSafeArea()
            VStack(spacing: 14) {
                Text("NO REP")
                    .font(Theme.display(150))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(.white)
                Text(detail.uppercased())
                    .font(.system(size: 16, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
        }
        .allowsHitTesting(false)
    }
}

struct PhoneMovedBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18, weight: .bold))
            Text("PHONE MOVED, NOT COUNTING")
                .font(Theme.display(26))
                .tracking(1.2)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(Color.black)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.warn))
        .padding(.horizontal, 16)
        .allowsHitTesting(false)
    }
}
