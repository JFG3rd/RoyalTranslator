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

    // Read the actual UITabBar frame from the UIKit hierarchy.
    // This works regardless of whether iOS puts the tab bar at the top or bottom.
    private func liveTabRects(screenSize: CGSize) -> [String: CGRect] {
        let tabBarFrame: CGRect

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first(where: { $0.isKeyWindow }),
           let tbc = findTabBarController(in: window.rootViewController) {
            tabBarFrame = tbc.tabBar.frame
        } else {
            // Fallback — should rarely fire; assume standard bottom tab bar
            let safeBottom = UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.windows.first?.safeAreaInsets.bottom }
                .first ?? 0
            tabBarFrame = CGRect(x: 0, y: screenSize.height - 49 - safeBottom,
                                 width: screenSize.width, height: 49)
        }

        let names = ["tab_dispatch", "tab_court", "tab_archives", "tab_favourites", "tab_realm"]
        let tabW = tabBarFrame.width / CGFloat(names.count)
        var result: [String: CGRect] = [:]
        for (i, name) in names.enumerated() {
            result[name] = CGRect(
                x: tabBarFrame.minX + tabW * CGFloat(i) + 6,
                y: tabBarFrame.minY + 4,
                width: tabW - 12,
                height: tabBarFrame.height - 8
            )
        }
        return result
    }

    private func findTabBarController(in vc: UIViewController?) -> UITabBarController? {
        guard let vc else { return nil }
        if let tbc = vc as? UITabBarController { return tbc }
        for child in vc.children {
            if let found = findTabBarController(in: child) { return found }
        }
        return nil
    }
}

extension Notification.Name {
    static let redispatchText = Notification.Name("com.royaltranslator.redispatchText")
}
