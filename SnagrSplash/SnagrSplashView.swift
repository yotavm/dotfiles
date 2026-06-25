//
//  SnagrSplashView.swift
//  Snagr Dining
//
//  A self-contained, dependency-free animated splash screen.
//
//  The animation is a "cloche reveal":
//    1. A silver dome (cloche) sits at center over a hidden app-icon tile.
//    2. The dome lifts away and fades — like a dish being served.
//    3. As it lifts, the tile + serif "S" spring up and a burst of food
//       emojis sprays outward (the food beat), then clears.
//    4. Steam wisps rise above the tile in a gentle loop.
//    5. The "Snagr / DINING" wordmark fades up.
//    6. The plate breathes (subtle continuous bob) at rest.
//
//  No Lottie required — everything is native SwiftUI so it runs in Previews
//  and adds zero binary weight. (A Lottie drop-in is described in README.md
//  if you'd rather ship a designer-authored .json later.)
//
//  Requires iOS 16+ (UnevenRoundedRectangle). Tested look matches
//  splash-preview.gif.
//

import SwiftUI

// MARK: - Splash Screen

struct SnagrSplashView: View {
    /// Tile + logo spring-up.
    @State private var revealed = false
    /// Cloche lift-away.
    @State private var lifted = false
    /// Looping ambient motion (kept separate so it doesn't restart the intro).
    @State private var steaming = false
    @State private var breathing = false
    /// One-shot food spray.
    @State private var burst = false

    /// Called when the intro finishes — hook your root navigation here.
    var onFinished: () -> Void = {}

    private let brand = Color(red: 0.07, green: 0.07, blue: 0.08)

    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.98, blue: 0.98)
                .ignoresSafeArea()

            VStack(spacing: 78) {
                Spacer()

                ZStack {
                    // soft "counter" shadow under the tile
                    Ellipse()
                        .fill(
                            RadialGradient(colors: [.black.opacity(0.16), .clear],
                                           center: .center, startRadius: 0, endRadius: 75)
                        )
                        .frame(width: 150, height: 24)
                        .offset(y: 92)
                        .opacity(revealed ? 1 : 0)

                    SteamView(active: steaming)
                        .frame(width: 110, height: 80)
                        .offset(y: -118)
                        .opacity(revealed ? 1 : 0)

                    appIconTile

                    FoodBurst(fire: burst)

                    ClocheView()
                        .offset(y: lifted ? -230 : 8)
                        .scaleEffect(lifted ? 0.7 : 1)
                        .opacity(lifted ? 0 : 1)
                }
                .frame(width: 200, height: 200)
                .offset(y: breathing ? -5 : 5)

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
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.white)
                .frame(width: 130, height: 130)
                .shadow(color: .black.opacity(0.14),
                        radius: revealed ? 24 : 0, x: 0, y: revealed ? 16 : 0)

            Text("S")
                .font(.system(size: 82, weight: .black, design: .serif))
                .foregroundStyle(brand)
        }
        .scaleEffect(revealed ? 1 : 0.4)
        .opacity(revealed ? 1 : 0)
        .offset(y: revealed ? 0 : 10)
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
        // Tile springs up + cloche lifts away (after a beat under the dome).
        withAnimation(.spring(response: 0.7, dampingFraction: 0.55).delay(0.55)) {
            revealed = true
        }
        withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 1.0).delay(0.55)) {
            lifted = true
        }
        // Food spray.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) { burst = true }
        // Ambient loops.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { steaming = true }
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true).delay(1.4)) {
            breathing = true
        }
        // Hand control back to the app once the intro reads.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { onFinished() }
    }
}

// MARK: - Cloche (silver dome cover)

private struct ClocheView: View {
    var body: some View {
        ZStack(alignment: .top) {
            UnevenRoundedRectangle(
                topLeadingRadius: 46, bottomLeadingRadius: 14,
                bottomTrailingRadius: 14, topTrailingRadius: 46, style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: [Color(white: 0.96), Color(white: 0.84),
                             Color(white: 0.73), Color(white: 0.91)],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .frame(width: 150, height: 88)
            .overlay(alignment: .topLeading) {
                Ellipse()
                    .fill(.white.opacity(0.45))
                    .frame(width: 34, height: 46)
                    .blur(radius: 4)
                    .offset(x: 24, y: 14)
            }
            .shadow(color: .black.opacity(0.18), radius: 12, y: 8)

            // knob
            Circle()
                .fill(
                    LinearGradient(colors: [Color(white: 0.94), Color(white: 0.78)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 20, height: 20)
                .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
                .offset(y: -13)
        }
        .offset(y: 35) // sit low so the flat base rests over the tile
    }
}

// MARK: - Food burst

private struct FoodBurst: View {
    var fire: Bool

    // emoji + radial target (matching the preview spray)
    private let items: [(String, CGSize, Double)] = [
        ("🍣", CGSize(width: -86, height: -30), -25),
        ("🍤", CGSize(width: -58, height: -78),  18),
        ("🍜", CGSize(width:   0, height: -96), -12),
        ("🥗", CGSize(width:  58, height: -78),  20),
        ("🍔", CGSize(width:  86, height: -30), -18),
        ("🍩", CGSize(width: -70, height:  24),  14),
        ("🍕", CGSize(width:  70, height:  24), -22),
    ]

    var body: some View {
        ZStack {
            ForEach(items.indices, id: \.self) { i in
                FoodParticle(emoji: items[i].0,
                             target: items[i].1,
                             rotation: items[i].2,
                             fire: fire)
            }
        }
    }
}

private struct FoodParticle: View {
    let emoji: String
    let target: CGSize
    let rotation: Double
    var fire: Bool

    @State private var progress: CGFloat = 0   // 0 = center, 1 = target, >1 = drift out
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0

    var body: some View {
        Text(emoji)
            .font(.system(size: 26))
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(x: target.width * progress,
                    y: target.height * progress - (progress > 1 ? 18 : 0))
            .rotationEffect(.degrees(rotation * Double(progress)))
            .onChange(of: fire) { _, go in
                guard go else { return }
                // pop outward + fade in
                withAnimation(.timingCurve(0.2, 0.9, 0.3, 1, duration: 0.55)) {
                    progress = 1; opacity = 1; scale = 1.15
                }
                // drift + fade away
                withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
                    progress = 1.25; opacity = 0; scale = 0.5
                }
            }
    }
}

// MARK: - Steam

private struct SteamView: View {
    var active: Bool
    var body: some View {
        HStack(spacing: 14) {
            SteamWisp(active: active, delay: 0.0)
            SteamWisp(active: active, delay: 0.35)
            SteamWisp(active: active, delay: 0.7)
        }
    }
}

private struct SteamWisp: View {
    var active: Bool
    var delay: Double
    @State private var phase: CGFloat = 0

    var body: some View {
        WispShape(phase: phase)
            .stroke(Color(red: 0.07, green: 0.07, blue: 0.08).opacity(0.28),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round))
            .frame(width: 18, height: 70)
            .opacity(active ? Double(1 - phase) : 0)
            .offset(y: active ? -phase * 26 : 0)
            .onChange(of: active) { _, isActive in
                guard isActive else { return }
                withAnimation(.easeOut(duration: 2.0)
                    .repeatForever(autoreverses: false).delay(delay)) { phase = 1 }
            }
    }
}

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

// MARK: - Preview

#Preview("Snagr Splash") {
    SnagrSplashView()
}
