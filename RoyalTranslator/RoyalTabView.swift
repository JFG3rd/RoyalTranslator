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
                    let tabRects = liveTabRects(screenSize: geo.size)
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

    // Build tab spotlight rects using the live UITabBar frame when available,
    // falling back to safe-area-inset heuristics for iOS 18 iPad where the
    // tab bar is rendered at the top as a SwiftUI view with no UITabBar subview.
    private func liveTabRects(screenSize: CGSize) -> [String: CGRect] {
        let names = ["tab_dispatch", "tab_court", "tab_archives", "tab_favourites", "tab_realm"]

        // 1. Search the entire view hierarchy for a UITabBar view (not just UITabBarController).
        //    Convert its frame to window-root coordinates so they match the overlay space.
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first(where: { $0.isKeyWindow }),
           let tabBar = findTabBarView(in: window) {
            let frame = tabBar.convert(tabBar.bounds, to: window)
            if frame.width > 10 && frame.height > 10 {
                return tabRects(in: frame, names: names)
            }
        }

        // 2. Fallback: derive position from window safe-area insets.
        //    On iPad iOS 18 the tab bar is at the TOP; the combined top safe area
        //    (status bar + tab bar) is noticeably taller than the status bar alone.
        //    On iPhone the tab bar is at the BOTTOM; bottom inset > 40pt.
        let safeInsets: UIEdgeInsets = {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let win = scene.windows.first(where: { $0.isKeyWindow }) {
                return win.safeAreaInsets
            }
            return .zero
        }()

        let barH: CGFloat = 49
        let frame: CGRect
        if safeInsets.bottom > 40 {
            // iPhone-style: tab bar at the bottom
            frame = CGRect(x: 0, y: screenSize.height - barH - safeInsets.bottom,
                           width: screenSize.width, height: barH)
        } else {
            // iPad iOS 18-style: tab bar at the top.
            // The top safe area covers status bar + tab bar. Approximate tab bar
            // as occupying the lower portion of that inset.
            let topInset = max(safeInsets.top, barH + 20) // at least status+bar
            frame = CGRect(x: 0, y: topInset - barH,
                           width: screenSize.width, height: barH)
        }
        return tabRects(in: frame, names: names)
    }

    private func tabRects(in frame: CGRect, names: [String]) -> [String: CGRect] {
        let tabW = frame.width / CGFloat(names.count)
        var result: [String: CGRect] = [:]
        for (i, name) in names.enumerated() {
            result[name] = CGRect(
                x: frame.minX + tabW * CGFloat(i) + 6,
                y: frame.minY + 4,
                width: tabW - 12,
                height: frame.height - 8
            )
        }
        return result
    }

    // Search the full UIView tree for a UITabBar (works even when there is no UITabBarController).
    private func findTabBarView(in view: UIView) -> UITabBar? {
        if let bar = view as? UITabBar { return bar }
        for sub in view.subviews {
            if let found = findTabBarView(in: sub) { return found }
        }
        return nil
    }
}

extension Notification.Name {
    static let redispatchText = Notification.Name("com.royaltranslator.redispatchText")
}
