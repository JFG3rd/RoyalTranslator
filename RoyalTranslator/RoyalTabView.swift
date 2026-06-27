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
        // The GeometryReader uses .ignoresSafeArea() so geo.size == full screen size,
        // which lets us accurately calculate where the tab bar items sit.
        .overlayPreferenceValue(CoachAnchorKey.self) { anchors in
            if showCoachTutorial {
                GeometryReader { geo in
                    let safeBottom = geo.safeAreaInsets.bottom
                    let barH: CGFloat = 49
                    let barTop = geo.size.height - barH - safeBottom
                    let tabW = geo.size.width / 5
                    let tabRects: [String: CGRect] = [
                        "tab_dispatch":   CGRect(x: tabW * 0 + 6, y: barTop + 4, width: tabW - 12, height: barH - 8),
                        "tab_court":      CGRect(x: tabW * 1 + 6, y: barTop + 4, width: tabW - 12, height: barH - 8),
                        "tab_archives":   CGRect(x: tabW * 2 + 6, y: barTop + 4, width: tabW - 12, height: barH - 8),
                        "tab_favourites": CGRect(x: tabW * 3 + 6, y: barTop + 4, width: tabW - 12, height: barH - 8),
                        "tab_realm":      CGRect(x: tabW * 4 + 6, y: barTop + 4, width: tabW - 12, height: barH - 8),
                    ]
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
}

extension Notification.Name {
    static let redispatchText = Notification.Name("com.royaltranslator.redispatchText")
}
