import SwiftUI

struct RoyalTabView: View {
    @EnvironmentObject var service: TranslatorService
    @EnvironmentObject var court: CourtViewModel
    @Environment(\.colorScheme) var colorScheme

    @AppStorage("fontSizeBase") private var fontSizeBase: Double = 17
    @AppStorage("hideTutorial") private var hideTutorial = false
    @State private var selectedTab = 0
    @State private var showCoachTutorial = false
    @State private var coachStep = 0

    var theme: AppTheme { AppTheme(scheme: colorScheme, base: CGFloat(fontSizeBase)) }

    var body: some View {
        TabView(selection: $selectedTab) {
            // 0 — Sendung / Dispatch
            DispatchView(theme: theme) {
                coachStep = 0
                withAnimation { showCoachTutorial = true }
            }
            .environmentObject(court)
            .environmentObject(service)
            .tabItem { Label("tab_dispatch", systemImage: "scroll.fill") }
            .tag(0)

            // 1 — Hof / Court
            NavigationStack {
                CourtView(theme: theme, sheetMode: false)
                    .environmentObject(court)
                    .navigationTitle(Text("tab_court"))
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem { Label("tab_court", systemImage: "person.3.fill") }
            .tag(1)

            // 2 — Archiv / Archives
            NavigationStack {
                ArchivesView(theme: theme, selectedTab: $selectedTab)
                    .environmentObject(service)
                    .environmentObject(court)
            }
            .tabItem { Label("tab_archives", systemImage: "scroll") }
            .tag(2)

            // 3 — Favoriten / Favourites
            NavigationStack {
                FavouritesView(theme: theme)
                    .environmentObject(service)
            }
            .tabItem { Label("tab_favourites", systemImage: "heart.fill") }
            .tag(3)

            // 4 — Reich / Realm
            RealmView(theme: theme)
                .environmentObject(court)
                .tabItem { Label("tab_realm", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .tint(theme.accent)
        .onReceive(NotificationCenter.default.publisher(for: .redispatch)) { notification in
            if let text = notification.object as? String {
                NotificationCenter.default.post(name: .redispatchText, object: text)
                selectedTab = 0
            }
        }
        // Coach mark overlay.
        // GeometryReader is inside the overlay with .ignoresSafeArea() so geo.size == full screen.
        // Tab bar rects are read from UIKit directly so they work regardless of whether iOS
        // places the tab bar at the top or the bottom.
        .overlayPreferenceValue(CoachAnchorKey.self) { anchors in
            if showCoachTutorial {
                GeometryReader { geo in
                    // geo.safeAreaInsets is still valid even with .ignoresSafeArea() below —
                    // it reflects the true window safe area (status bar + tab bar + home indicator).
                    // iPad iOS 18: top tab bar → safeTop > safeBot
                    // iPhone:      bottom tab bar → safeBot > safeTop
                    let tabRects = tabBarRects(geo: geo)
                    CoachMarkOverlay(
                        steps: CoachStep.dispatchSteps,
                        anchors: anchors,
                        extraRects: tabRects,
                        geo: geo,
                        currentStep: $coachStep,
                        theme: theme,
                        onDismiss: {
                            withAnimation { showCoachTutorial = false }
                            coachStep = 0
                            hideTutorial = true
                        }
                    )
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .onAppear {
            if !hideTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation { showCoachTutorial = true }
                }
            }
        }
    }

    // Derive tab item rects purely from SwiftUI's GeometryProxy safe-area insets.
    // Even inside .ignoresSafeArea(), geo.safeAreaInsets reflects the true window insets:
    //   iPad iOS 18 (top tab bar):    safeTop  > safeBot  → bar spans the top inset
    //   iPhone      (bottom tab bar): safeBot  > safeTop  → bar spans the bottom inset
    private func tabBarRects(geo: GeometryProxy) -> [String: CGRect] {
        let names = ["tab_dispatch", "tab_court", "tab_archives", "tab_favourites", "tab_realm"]
        let safeTop = geo.safeAreaInsets.top
        let safeBot = geo.safeAreaInsets.bottom
        let w = geo.size.width
        let h = geo.size.height

        let barRect: CGRect
        if safeTop > safeBot {
            // Tab bar is at the top — its region is the full top safe area
            barRect = CGRect(x: 0, y: 0, width: w, height: safeTop)
        } else {
            // Tab bar is at the bottom — its region is the full bottom safe area
            barRect = CGRect(x: 0, y: h - safeBot, width: w, height: safeBot)
        }

        let tabW = w / CGFloat(names.count)
        var result: [String: CGRect] = [:]
        for (i, name) in names.enumerated() {
            // Centre the spotlight in the lower 60% of the bar region (avoids status bar)
            let spotY = barRect.minY + barRect.height * 0.4
            let spotH = barRect.height * 0.55
            result[name] = CGRect(x: tabW * CGFloat(i) + 6, y: spotY,
                                  width: tabW - 12, height: spotH)
        }
        return result
    }
}

extension Notification.Name {
    static let redispatchText = Notification.Name("com.royaltranslator.redispatchText")
}
