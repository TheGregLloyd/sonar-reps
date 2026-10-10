// HowItWorks.swift
// Three steps shown on first launch and from the info button: where the phone
// goes, hands off, and what the sonar is doing. Claims nothing the README does not.

import SwiftUI

struct HowItWorks: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack(spacing: 12) {
                LogoMark().frame(width: 34, height: 34)
                Text("SONAR REPS")
                    .font(Theme.display(26))
                    .tracking(3)
                    .foregroundStyle(Theme.text)
            }
            .padding(.top, 8)

            Step(number: 1, title: "Phone on the floor",
                 text: "Face-up, under your chest. Volume at about three quarters.") {
                PlacementSketch()
            }
            Step(number: 2, title: "Start, then hands off",
                 text: "Moving the phone pauses counting. Full reps count; shallow ones show NO REP.") {
                CountSketch()
            }
            Step(number: 3, title: "Sound you cannot hear",
                 text: "Three tones near 19 kHz echo off your chest. No camera, nothing to wear.") {
                LogoMark().padding(6)
            }

            Spacer(minLength: 0)

            Button { dismiss() } label: {
                Text("GOT IT")
                    .font(Theme.display(22))
                    .tracking(2)
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.accent))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.bg.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

private struct Step<Art: View>: View {
    let number: Int
    let title: String
    let text: String
    @ViewBuilder let art: () -> Art

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            art()
                .frame(width: 76, height: 76)
                .background(RoundedRectangle(cornerRadius: 16).fill(Theme.surface))
            VStack(alignment: .leading, spacing: 6) {
                Caption("Step \(number)", color: Theme.accent, size: 10)
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.text)
                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// A figure in the push-up position with the phone under the chest.
private struct PlacementSketch: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let floorY = h * 0.78
            var floor = Path()
            floor.move(to: CGPoint(x: w * 0.08, y: floorY))
            floor.addLine(to: CGPoint(x: w * 0.92, y: floorY))
            ctx.stroke(floor, with: .color(Theme.faint), lineWidth: 1.5)

            // Body: feet on the right, head on the left, arms straight down.
            var body = Path()
            body.move(to: CGPoint(x: w * 0.86, y: floorY - 2))
            body.addLine(to: CGPoint(x: w * 0.3, y: h * 0.4))
            ctx.stroke(body, with: .color(Theme.text), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            var arm = Path()
            arm.move(to: CGPoint(x: w * 0.34, y: h * 0.42))
            arm.addLine(to: CGPoint(x: w * 0.34, y: floorY - 2))
            ctx.stroke(arm, with: .color(Theme.text), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.13, y: h * 0.3, width: w * 0.13, height: w * 0.13)),
                     with: .color(Theme.text))

            // Phone under the chest.
            let phone = CGRect(x: w * 0.42, y: floorY - 5, width: w * 0.18, height: 4)
            ctx.fill(Path(roundedRect: phone, cornerRadius: 2), with: .color(Theme.accent))
            var echo = Path()
            echo.addArc(center: CGPoint(x: w * 0.51, y: floorY - 6), radius: w * 0.1,
                        startAngle: .degrees(220), endAngle: .degrees(320), clockwise: false)
            ctx.stroke(echo, with: .color(Theme.accent.opacity(0.7)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }
    }
}

/// A count with a NO REP tag beside it.
private struct CountSketch: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("12")
                .font(Theme.display(34))
                .foregroundStyle(Theme.text)
            Text("NO REP")
                .font(.system(size: 8, weight: .bold))
                .tracking(1)
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 3).fill(Theme.noRep))
        }
    }
}
