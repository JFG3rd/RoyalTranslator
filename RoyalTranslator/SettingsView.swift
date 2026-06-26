import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @Binding var defaultStyleIDsRaw: String
    let theme: AppTheme

    @State private var currentIcon: String? = UIApplication.shared.alternateIconName
    @State private var expandedCategory: FilterCategory? = nil
    @AppStorage("persist_api_key") private var persistAPIKey = false
    @AppStorage("fontSizeBase") private var fontSizeBase: Double = 17
    @AppStorage("hideTutorial") private var hideTutorial = false
    @State private var showTutorial = false

    var defaultStyleIDs: Set<String> {
        Set(defaultStyleIDsRaw.split(separator: ",").map(String.init))
    }

    // Live theme that reflects slider changes immediately
    var liveTheme: AppTheme { AppTheme(scheme: theme.scheme, base: CGFloat(fontSizeBase)) }

    var body: some View {
        ZStack {
            LinearGradient(colors: [theme.bg1, theme.bg2],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // Header
                    HStack {
                        Text("settings")
                            .font(.custom("Georgia", size: liveTheme.scaled(22))).fontWeight(.bold)
                            .foregroundColor(liveTheme.accent)
                        Spacer()
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark")
                                .foregroundColor(liveTheme.faded).font(.system(size: liveTheme.scaled(18)))
                        }
                    }

                    // Font Size
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("FONT_SIZE_GROUP")
                        VStack(spacing: 10) {
                            HStack {
                                Text("A").font(.custom("Georgia", size: 13)).foregroundColor(liveTheme.faded)
                                Slider(
                                    value: $fontSizeBase,
                                    in: 13...23,
                                    step: 1
                                )
                                .tint(liveTheme.accent)
                                Text("A").font(.custom("Georgia", size: 21)).foregroundColor(liveTheme.faded)
                            }
                            Text(fontSizeSampleText)
                                .font(.custom("Georgia", size: liveTheme.scaled(15)))
                                .foregroundColor(liveTheme.inkDark).italic()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .settingsCard(theme: liveTheme)

                    // Default Styles
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("default_styles")
                        Text("default_styles_hint")
                            .font(.custom("Georgia", size: liveTheme.scaled(12)))
                            .foregroundColor(liveTheme.faded).italic()

                        ForEach(FilterCategory.allCases.filter { $0 != .all }) { category in
                            categorySection(category)
                        }
                    }
                    .settingsCard(theme: liveTheme)

                    // Tutorial
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("tutorial_settings_header")
                        Toggle(isOn: Binding(
                            get: { !hideTutorial },
                            set: { hideTutorial = !$0 }
                        )) {
                            Text("tutorial_show_on_launch")
                                .font(.custom("Georgia", size: liveTheme.scaled(14)))
                                .foregroundColor(liveTheme.inkDark)
                        }
                        .tint(liveTheme.accent)
                        Button(action: { showTutorial = true }) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                Text("tutorial_show_now")
                            }
                            .font(.custom("Georgia", size: liveTheme.scaled(14)))
                            .foregroundColor(liveTheme.accent)
                        }
                    }
                    .settingsCard(theme: liveTheme)
                    .sheet(isPresented: $showTutorial) {
                        TutorialView(isPresented: $showTutorial, theme: liveTheme)
                    }

                    // API Key
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("API_KEY_GROUP")
                        Toggle(isOn: $persistAPIKey) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("PERSIST_API_KEY_TITLE")
                                    .font(.custom("Georgia", size: liveTheme.scaled(14)))
                                    .foregroundColor(liveTheme.inkDark)
                                Text(persistAPIKey ? "persist_api_key_on_hint" : "persist_api_key_off_hint")
                                    .font(.custom("Georgia", size: liveTheme.scaled(11)))
                                    .foregroundColor(liveTheme.faded)
                            }
                        }
                        .tint(liveTheme.accent)
                    }
                    .settingsCard(theme: liveTheme)

                    // App Icon
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("app_icon")
                        HStack(spacing: 20) {
                            IconChoice(labelKey: "royal", imageName: "AppIconLight",
                                       isSelected: currentIcon == nil, theme: liveTheme) { setIcon(nil) }
                            IconChoice(labelKey: "dark", imageName: "AppIconDark_120",
                                       isSelected: currentIcon == "AppIconDark", theme: liveTheme) { setIcon("AppIconDark") }
                        }
                    }
                    .settingsCard(theme: liveTheme)
                }
                .padding(24)
            }
        }
        .font(.custom("Georgia", size: liveTheme.scaled(16)))
        .foregroundColor(liveTheme.inkDark)
    }

    private var fontSizeSampleText: String {
        "\(Int(fontSizeBase))pt · " + String(localized: "app_subtitle")
    }

    // MARK: - Category Section

    func categorySection(_ category: FilterCategory) -> some View {
        let styles = TranslationStyle.all.filter { $0.category == category }
        let onCount = styles.filter { defaultStyleIDs.contains($0.id) }.count
        let isExpanded = expandedCategory == category

        return VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedCategory = isExpanded ? nil : category
                }
            }) {
                HStack {
                    Text(category.emoji)
                    Text(category.locKey)
                        .font(.custom("Georgia", size: liveTheme.scaled(15)))
                        .foregroundColor(liveTheme.inkDark)
                    Spacer()
                    if onCount > 0 {
                        Text("\(onCount) on")
                            .font(.custom("Georgia", size: liveTheme.scaled(11)))
                            .foregroundColor(liveTheme.accent)
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: liveTheme.scaled(12)))
                        .foregroundColor(liveTheme.faded)
                }
                .padding(.vertical, 8)
            }

            if isExpanded {
                Divider().background(liveTheme.faded.opacity(0.4))
                VStack(spacing: 0) {
                    ForEach(styles) { style in
                        let isOn = defaultStyleIDs.contains(style.id)
                        Toggle(isOn: Binding(
                            get: { isOn },
                            set: { enabled in
                                var ids = defaultStyleIDs
                                if enabled { ids.insert(style.id) } else { ids.remove(style.id) }
                                defaultStyleIDsRaw = ids.joined(separator: ",")
                            }
                        )) {
                            HStack(spacing: 8) {
                                Text(style.emoji)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(style.label)
                                        .font(.custom("Georgia", size: liveTheme.scaled(14)))
                                        .foregroundColor(liveTheme.inkDark)
                                    HStack(spacing: 2) {
                                        Text(style.language.locKey)
                                        Text("·")
                                        Text(style.gender.locKey)
                                    }
                                    .font(.custom("Georgia", size: liveTheme.scaled(10)))
                                    .foregroundColor(liveTheme.faded)
                                }
                            }
                        }
                        .tint(liveTheme.accent)
                        .padding(.vertical, 6)
                        if style.id != styles.last?.id {
                            Divider().background(liveTheme.faded.opacity(0.2))
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 4)
        .background(liveTheme.cardFill.opacity(0.5))
        .cornerRadius(6)
    }

    func sectionHeader(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.custom("Georgia", size: liveTheme.scaled(13)))
            .kerning(1.5).textCase(.uppercase)
            .foregroundColor(liveTheme.faded)
    }

    private func setIcon(_ name: String?) {
        UIApplication.shared.setAlternateIconName(name) { error in
            if error == nil { currentIcon = name }
        }
    }
}

// MARK: - Icon Choice

struct IconChoice: View {
    let labelKey: LocalizedStringKey
    let imageName: String
    let isSelected: Bool
    let theme: AppTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                if let uiImage = UIImage(named: imageName) {
                    Image(uiImage: uiImage)
                        .resizable().aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80).cornerRadius(18)
                        .overlay(RoundedRectangle(cornerRadius: 18)
                            .stroke(isSelected ? theme.accent : theme.faded, lineWidth: isSelected ? 3 : 1))
                } else {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.gray.opacity(0.3)).frame(width: 80, height: 80)
                }
                Text(labelKey)
                    .font(.custom("Georgia", size: theme.scaled(13)))
                    .foregroundColor(isSelected ? theme.accent : theme.faded)
            }
        }
    }
}

// MARK: - Card Modifier

private struct SettingsCardModifier: ViewModifier {
    let theme: AppTheme
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(theme.cardFill)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.cardStroke, lineWidth: 1))
    }
}

extension View {
    func settingsCard(theme: AppTheme) -> some View {
        modifier(SettingsCardModifier(theme: theme))
    }
}
