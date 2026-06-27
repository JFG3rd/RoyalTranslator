import SwiftUI

struct RealmView: View {
    @EnvironmentObject var court: CourtViewModel
    let theme: AppTheme

    @AppStorage("persist_api_key") private var persistAPIKey = false
    @AppStorage("fontSizeBase") private var fontSizeBase: Double = 17
    @AppStorage("hideTutorial") private var hideTutorial = false
    @State private var showTutorial = false
    @State private var showClearAlert = false
    @State private var showCourtDefaults = false
    @State private var currentIcon: String? = UIApplication.shared.alternateIconName

    var liveTheme: AppTheme { AppTheme(scheme: theme.scheme, base: CGFloat(fontSizeBase)) }

    var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [liveTheme.bg1, liveTheme.bg2],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                Form {
                    // Appearance
                    Section {
                        fontSizeRow
                        NavigationLink {
                            iconPickerView
                        } label: {
                            Label("app_icon", systemImage: "app.badge")
                                .font(.custom("Georgia", size: liveTheme.scaled(14)))
                        }
                    } header: { sectionHeader("realm_appearance") }

                    // The Court
                    Section {
                        NavigationLink {
                            CourtView(theme: liveTheme, sheetMode: false)
                                .environmentObject(court)
                                .navigationTitle(Text("realm_default_chars"))
                                .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            HStack {
                                Label("realm_default_chars", systemImage: "person.3")
                                    .font(.custom("Georgia", size: liveTheme.scaled(14)))
                                Spacer()
                                Text("\(court.activeStyleIDs.count)")
                                    .font(.custom("Georgia", size: liveTheme.scaled(12)))
                                    .foregroundColor(liveTheme.faded)
                            }
                        }
                        Button(action: { court.saveAsDefaults() }) {
                            Label("realm_save_defaults", systemImage: "checkmark.circle")
                                .font(.custom("Georgia", size: liveTheme.scaled(14)))
                                .foregroundColor(liveTheme.accent)
                        }
                    } header: { sectionHeader("realm_court") }

                    // API Key
                    Section {
                        Toggle(isOn: $persistAPIKey) {
                            Text("PERSIST_API_KEY_TITLE")
                                .font(.custom("Georgia", size: liveTheme.scaled(14)))
                        }
                        .tint(liveTheme.accent)

                        Button(role: .destructive, action: { showClearAlert = true }) {
                            Label("realm_clear_key", systemImage: "key.slash")
                                .font(.custom("Georgia", size: liveTheme.scaled(14)))
                        }
                    } header: { sectionHeader("API_KEY_GROUP") }

                    // Help
                    Section {
                        Toggle(isOn: Binding(
                            get: { !hideTutorial },
                            set: { hideTutorial = !$0 }
                        )) {
                            Text("tutorial_show_on_launch")
                                .font(.custom("Georgia", size: liveTheme.scaled(14)))
                        }
                        .tint(liveTheme.accent)

                        Button(action: { showTutorial = true }) {
                            Label("tutorial_show_now", systemImage: "questionmark.circle")
                                .font(.custom("Georgia", size: liveTheme.scaled(14)))
                                .foregroundColor(liveTheme.accent)
                        }
                    } header: { sectionHeader("realm_help") }

                    // About
                    Section {
                        HStack {
                            Text("realm_version")
                                .font(.custom("Georgia", size: liveTheme.scaled(14)))
                            Spacer()
                            Text(appVersion)
                                .font(.custom("Georgia", size: liveTheme.scaled(13)))
                                .foregroundColor(liveTheme.faded)
                        }
                    } header: { sectionHeader("realm_about") }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(Text("realm_title"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .font(.custom("Georgia", size: liveTheme.scaled(14)))
        .foregroundColor(liveTheme.inkDark)
        .sheet(isPresented: $showTutorial) {
            TutorialView(isPresented: $showTutorial, theme: liveTheme)
        }
        .alert("realm_clear_key_confirm", isPresented: $showClearAlert) {
            Button("realm_clear_key", role: .destructive) {
                KeychainHelper.delete()
            }
            Button("cancel", role: .cancel) {}
        } message: {
            Text("realm_clear_key_message")
        }
    }

    // MARK: - Font size row

    var fontSizeRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("FONT_SIZE_GROUP", systemImage: "textformat.size")
                .font(.custom("Georgia", size: liveTheme.scaled(14)))
            HStack {
                Text("A").font(.custom("Georgia", size: 13)).foregroundColor(liveTheme.faded)
                Slider(value: $fontSizeBase, in: 13...23, step: 1).tint(liveTheme.accent)
                Text("A").font(.custom("Georgia", size: 21)).foregroundColor(liveTheme.faded)
            }
            Text(fontSizePreview)
                .font(.custom("Georgia", size: liveTheme.scaled(13))).italic()
                .foregroundColor(liveTheme.faded)
        }
        .padding(.vertical, 4)
    }

    var fontSizePreview: String {
        "\(Int(fontSizeBase))pt · " + String(localized: "app_subtitle")
    }

    // MARK: - Icon picker

    var iconPickerView: some View {
        ZStack {
            LinearGradient(colors: [liveTheme.bg1, liveTheme.bg2],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            HStack(spacing: 24) {
                IconChoice(labelKey: "royal", imageName: "AppIconLight",
                           isSelected: currentIcon == nil, theme: liveTheme) { setIcon(nil) }
                IconChoice(labelKey: "dark", imageName: "AppIconDark_120",
                           isSelected: currentIcon == "AppIconDark", theme: liveTheme) { setIcon("AppIconDark") }
            }
            .padding(32)
        }
        .navigationTitle(Text("app_icon"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

    func sectionHeader(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.custom("Georgia", size: liveTheme.scaled(11)))
            .kerning(1.5).textCase(.uppercase)
            .foregroundColor(liveTheme.faded)
    }

    func setIcon(_ name: String?) {
        UIApplication.shared.setAlternateIconName(name) { error in
            if error == nil { currentIcon = name }
        }
    }
}
