import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @Binding var defaultStyleIDsRaw: String
    let theme: AppTheme

    @State private var currentIcon: String? = UIApplication.shared.alternateIconName
    @State private var expandedCategory: FilterCategory? = nil

    var defaultStyleIDs: Set<String> {
        Set(defaultStyleIDsRaw.split(separator: ",").map(String.init))
    }

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
                            .font(.custom("Georgia", size: 22)).fontWeight(.bold)
                            .foregroundColor(theme.accent)
                        Spacer()
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark")
                                .foregroundColor(theme.faded).font(.system(size: 18))
                        }
                    }

                    // Default Styles
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("default_styles")
                        Text("default_styles_hint")
                            .font(.custom("Georgia", size: 12))
                            .foregroundColor(theme.faded).italic()

                        ForEach(FilterCategory.allCases.filter { $0 != .all }) { category in
                            categorySection(category)
                        }
                    }
                    .settingsCard(theme: theme)

                    // App Icon
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader("app_icon")
                        HStack(spacing: 20) {
                            IconChoice(labelKey: "royal", imageName: "AppIconLight",
                                       isSelected: currentIcon == nil, theme: theme) { setIcon(nil) }
                            IconChoice(labelKey: "dark", imageName: "AppIconDark_120",
                                       isSelected: currentIcon == "AppIconDark", theme: theme) { setIcon("AppIconDark") }
                        }
                    }
                    .settingsCard(theme: theme)
                }
                .padding(24)
            }
        }
        .font(.custom("Georgia", size: 16))
        .foregroundColor(theme.inkDark)
    }

    // MARK: - Category Section

    func categorySection(_ category: FilterCategory) -> some View {
        let styles = TranslationStyle.all.filter { $0.category == category }
        let onCount = styles.filter { defaultStyleIDs.contains($0.id) }.count
        let isExpanded = expandedCategory == category

        return VStack(spacing: 0) {
            // Section header row
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedCategory = isExpanded ? nil : category
                }
            }) {
                HStack {
                    Text(category.emoji)
                    Text(category.locKey)
                        .font(.custom("Georgia", size: 15))
                        .foregroundColor(theme.inkDark)
                    Spacer()
                    if onCount > 0 {
                        Text("\(onCount) on")
                            .font(.custom("Georgia", size: 11))
                            .foregroundColor(theme.accent)
                    }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(theme.faded)
                }
                .padding(.vertical, 8)
            }

            if isExpanded {
                Divider().background(theme.faded.opacity(0.4))
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
                                        .font(.custom("Georgia", size: 14))
                                        .foregroundColor(theme.inkDark)
                                    HStack(spacing: 2) {
                                        Text(style.language.locKey)
                                        Text("·")
                                        Text(style.gender.locKey)
                                    }
                                    .font(.custom("Georgia", size: 10))
                                    .foregroundColor(theme.faded)
                                }
                            }
                        }
                        .tint(theme.accent)
                        .padding(.vertical, 6)
                        if style.id != styles.last?.id {
                            Divider().background(theme.faded.opacity(0.2))
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 4)
        .background(theme.cardFill.opacity(0.5))
        .cornerRadius(6)
    }

    func sectionHeader(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.custom("Georgia", size: 13))
            .kerning(1.5).textCase(.uppercase)
            .foregroundColor(theme.faded)
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
                    .font(.custom("Georgia", size: 13))
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
