// Verdicts.swift
// The two states that must read from a metre away mid push-up:
// a refused movement (full-screen red) and the phone itself moving (amber banner).

import SwiftUI

struct NoRepOverlay: View {
    let detail: String

    var body: some View {
        ZStack {
            Theme.noRepFill.ignoresSafeArea()
            VStack(spacing: 14) {
                Text("NO REP")
                    .font(Theme.display(150))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.system(size: 18, weight: .medium))
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
            Text("Phone moved. Keep it still.")
                .font(.system(size: 19, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(Theme.warnInk)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.warnFill))
        .padding(.horizontal, 16)
        .allowsHitTesting(false)
    }
}
