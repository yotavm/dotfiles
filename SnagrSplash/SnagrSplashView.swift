//
//  SnagrSplashView.swift
//  Snagr Dining
//
//  A self-contained, dependency-free animated splash screen.
//
//  The animation is a "plated reveal":
//    1. The white app-icon tile springs in with a soft bounce + shadow.
//    2. The serif "S" logo draws/scales into place.
//    3. Steam puffs rise above the tile in a gentle loop (the "hot food" beat).
//    4. A fork.knife accent rotates in.
//    5. The "Snagr Dining" wordmark fades up.
//    6. The whole plate breathes (subtle continuous bob).
//
//  No Lottie required — everything is native SwiftUI so it runs in Previews
//  and adds zero binary weight. (A Lottie drop-in is described in README.md
//  if you'd rather ship a designer-authored .json later.)
//

import SwiftUI

// MARK: - Splash Screen

struct SnagrSplashView: View {
    /// Drives every staged animation. Flip to `true` once on appear.
    @State private var revealed = false
    /// Independent looping flags so steam / breathing don't restart with the reveal.
    @State private var steaming = false
    @State private var breathing = false

    /// Called when the intro finishes — hook your root navigation here.
    var onFinished: () -> Void = {}

    private let brand = Color(red: 0.07, green: 0.07, blue: 0.08)

    var body: some View {
        ZStack {
            // Match the screenshot: clean off-white backdrop.
            Color(red: 0.98, green: 0.98, blue: 0.98)
                .ignoresSafeArea()

            VStack(spacing: 80) {
                Spacer()

                ZStack {
                    SteamView(active: steaming)
                        .frame(width: 120, height: 90)
                        .offset(y: -118)
                        .opacity(revealed ? 1 : 0)

                    appIconTile

                    ForkKnifeAccent(revealed: revealed)
                        .offset(y: 112)
                }
                .offset(y: breathing ? -6 : 6)

                wordmark
                    .opacity(revealed ? 1 : 0)
                    .offset(y: revealed ? 0 : 16)

                Spacer()
            }
        }
        .onAppear(perform: runIntro)
    }

    // MARK: Pieces

    private var appIconTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(.white)
                .frame(width: 168, height: 168)
                .shadow(color: .black.opacity(0.12),
                        radius: revealed ? 28 : 0,
                        x: 0, y: revealed ? 18 : 0)

            Text("S")
                .font(.system(size: 104, weight: .black, design: .serif))
                .foregroundStyle(brand)
                .scaleEffect(x: revealed ? 1 : 0.7,
                             y: revealed ? 1 : 0.7)
                .opacity(revealed ? 1 : 0)
        }
        .scaleEffect(revealed ? 1 : 0.55)
        .opacity(revealed ? 1 : 0)
        .rotation3DEffect(.degrees(revealed ? 0 : 28),
                          axis: (x: 1, y: 0, z: 0))
    }

    private var wordmark: some View {
        VStack(spacing: 2) {
            Text("Snagr")
                .font(.system(size: 30, weight: .heavy, design: .serif))
                .foregroundStyle(brand)
            Text("DINING")
                .font(.system(size: 13, weight: .semibold))
                .tracking(6)
                .foregroundStyle(brand.opacity(0.55))
        }
    }

    // MARK: Timeline

    private func runIntro() {
        // 1. Tile + logo spring in.
        withAnimation(.spring(response: 0.7, dampingFraction: 0.55)) {
            revealed = true
        }
        // 2. Start the looping ambient motion once the tile has settled.
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            breathing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            steaming = true
        }
        // 3. Hand control back to the app after the intro reads.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            onFinished()
        }
    }
}

// MARK: - Steam

/// Three wavy lines that rise, drift sideways, and fade — looped.
private struct SteamView: View {
    var active: Bool

    var body: some View {
        HStack(spacing: 16) {
            steamLine(delay: 0.0)
            steamLine(delay: 0.35)
            steamLine(delay: 0.7)
        }
    }

    private func steamLine(delay: Double) -> some View {
        SteamWisp(active: active, delay: delay)
    }
}

private struct SteamWisp: View {
    var active: Bool
    var delay: Double

    @State private var phase: CGFloat = 0

    var body: some View {
        WispShape(phase: phase)
            .stroke(
                Color(red: 0.07, green: 0.07, blue: 0.08).opacity(0.28),
                style: StrokeStyle(lineWidth: 5, lineCap: .round)
            )
            .frame(width: 18, height: 70)
            // Rise + fade: opaque & low at the start, gone at the top.
            .opacity(active ? Double(1 - phase) : 0)
            .offset(y: active ? -phase * 26 : 0)
            .onAppear {
                guard active else { return }
                withAnimation(
                    .easeOut(duration: 2.0)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) { phase = 1 }
            }
            .onChange(of: active) { _, isActive in
                guard isActive else { return }
                withAnimation(
                    .easeOut(duration: 2.0)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) { phase = 1 }
            }
    }
}

/// A vertical sine wave whose horizontal wiggle is driven by `phase`.
private struct WispShape: Shape {
    var phase: CGFloat
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let amplitude = rect.width / 2
        let steps = 24
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let y = rect.height * (1 - t)
            let x = midX + sin((t * 4 * .pi) + phase * 2 * .pi) * amplitude
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        return path
    }
}

// MARK: - Fork & Knife accent

private struct ForkKnifeAccent: View {
    var revealed: Bool

    var body: some View {
        Image(systemName: "fork.knife")
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(Color(red: 0.07, green: 0.07, blue: 0.08).opacity(0.7))
            .padding(12)
            .background(
                Circle().fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            )
            .scaleEffect(revealed ? 1 : 0.2)
            .opacity(revealed ? 1 : 0)
            .rotationEffect(.degrees(revealed ? 0 : -120))
            .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.35),
                       value: revealed)
    }
}

// MARK: - Preview

#Preview("Snagr Splash") {
    SnagrSplashView()
}
