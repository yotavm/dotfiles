//
//  SnagrApp+Example.swift
//  Snagr Dining
//
//  Example of gating your real content behind the animated splash.
//  Delete this file (or fold it into your existing @main App) — it's here
//  to show the wiring, not to be shipped as-is.
//

import SwiftUI

struct RootView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            // Your real first screen (home / sign-in / tab bar) goes here.
            ContentPlaceholder()

            if showSplash {
                SnagrSplashView {
                    // Fade the splash out once the intro finishes.
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
}

private struct ContentPlaceholder: View {
    var body: some View {
        Text("Home")
            .font(.largeTitle.bold())
    }
}

#Preview {
    RootView()
}
