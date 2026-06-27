import SwiftUI

struct RoyalTabView: View {
    @EnvironmentObject var service: TranslatorService
    @EnvironmentObject var court: CourtViewModel
    @Environment(\.colorScheme) var colorScheme

    @AppStorage("fontSizeBase") private var fontSizeBase: Double = 17
    @State private var selectedTab = 0

    var theme: AppTheme { AppTheme(scheme: colorScheme, base: CGFloat(fontSizeBase)) }

    var body: some View {
        TabView(selection: $selectedTab) {

            // 0 — Dispatch
            DispatchView(theme: theme)
                .environmentObject(court)
                .environmentObject(service)
                .tabItem {
                    Label("tab_dispatch", systemImage: "scroll.fill")
                }
                .tag(0)

            // 1 — Court
            NavigationStack {
                CourtView(theme: theme, sheetMode: false)
                    .environmentObject(court)
                    .navigationTitle(Text("tab_court"))
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("tab_court", systemImage: "person.3.fill")
            }
            .tag(1)

            // 2 — Archives
            NavigationStack {
                ArchivesView(theme: theme, selectedTab: $selectedTab)
                    .environmentObject(service)
                    .environmentObject(court)
            }
            .tabItem {
                Label("tab_archives", systemImage: "scroll")
            }
            .tag(2)

            // 3 — Favourites
            NavigationStack {
                FavouritesView(theme: theme)
                    .environmentObject(service)
            }
            .tabItem {
                Label("tab_favourites", systemImage: "heart.fill")
            }
            .tag(3)

            // 4 — Realm (Settings)
            RealmView(theme: theme)
                .environmentObject(court)
                .tabItem {
                    Label("tab_realm", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .tint(theme.accent)
        .onReceive(NotificationCenter.default.publisher(for: .redispatch)) { notification in
            if let text = notification.object as? String {
                NotificationCenter.default.post(name: .redispatchText, object: text)
                selectedTab = 0
            }
        }
    }
}

extension Notification.Name {
    static let redispatchText = Notification.Name("com.royaltranslator.redispatchText")
}
