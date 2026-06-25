import SwiftUI

struct ContentView: View {
    @StateObject private var service = TranslatorService()
    @State private var inputText = ""
    @State private var apiKey = ""
    @State private var apiKeySet = false
    @State private var showAPIKey = false
    @State private var showSettings = false
    @FocusState private var inputFocused: Bool

    @AppStorage("defaultStyleIDs") private var defaultStyleIDsRaw: String =
        TranslationStyle.defaultIDs.joined(separator: ",")

    @State private var activeStyleIDs: Set<String> = TranslationStyle.defaultIDs
    @State private var filterLanguage: FilterLanguage = .all
    @State private var filterGender: FilterGender = .all
    @State private var filterCategory: FilterCategory = .all

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var hSizeClass

    var theme: AppTheme { AppTheme(scheme: colorScheme) }
    var isIpad: Bool { hSizeClass == .regular }

    var defaultStyleIDs: Set<String> {
        Set(defaultStyleIDsRaw.split(separator: ",").map(String.init))
    }

    var visibleStyles: [TranslationStyle] {
        TranslationStyle.all.filter {
            $0.matches(language: filterLanguage, gender: filterGender, category: filterCategory)
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [theme.bg1, theme.bg2],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            if !apiKeySet {
                keyEntryView
            } else {
                translatorView
            }
        }
        .font(.custom("Georgia", size: 16))
        .foregroundColor(theme.inkDark)
        .onAppear {
            handleSettingsBundleFlags()
            activeStyleIDs = defaultStyleIDs
            if let savedKey = KeychainHelper.load(), savedKey.hasPrefix("sk-") {
                apiKey = savedKey
                service.apiKey = savedKey
                apiKeySet = true
            }
        }
    }

    // MARK: - Settings bundle integration

    private func handleSettingsBundleFlags() {
        // Register defaults so the toggle starts false when first installed
        UserDefaults.standard.register(defaults: ["clear_api_key": false])
        if UserDefaults.standard.bool(forKey: "clear_api_key") {
            KeychainHelper.delete()
            UserDefaults.standard.set(false, forKey: "clear_api_key")
            apiKeySet = false
        }
    }

    // MARK: - API Key Screen

    var keyEntryView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("⚜️").font(.system(size: 40))
                Text("app_title")
                    .font(.custom("Georgia", size: 26)).fontWeight(.bold)
                    .foregroundColor(theme.accent)
                Text("app_subtitle")
                    .font(.custom("Georgia", size: 13))
                    .foregroundColor(theme.faded).italic()
            }

            VStack(spacing: 16) {
                Text("api_key_prompt")
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(theme.faded).italic()
                    .multilineTextAlignment(.center)

                HStack(spacing: 0) {
                    Group {
                        if showAPIKey {
                            TextField("sk-ant-...", text: $apiKey)
                        } else {
                            SecureField("sk-ant-...", text: $apiKey)
                        }
                    }
                    .font(.system(.body, design: .monospaced))
                    .padding(10)
                    .submitLabel(.go)
                    .onSubmit { commitKey() }

                    Button(action: { showAPIKey.toggle() }) {
                        Image(systemName: showAPIKey ? "eye.slash" : "eye")
                            .foregroundColor(theme.faded)
                            .padding(.vertical, 10).padding(.trailing, 6)
                    }
                    Button(action: {
                        if let s = UIPasteboard.general.string { apiKey = s }
                    }) {
                        Image(systemName: "doc.on.clipboard")
                            .foregroundColor(theme.faded)
                            .padding(.vertical, 10).padding(.trailing, 10)
                    }
                }
                .background(theme.inputFill)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(theme.faded, lineWidth: 1))

                Button(action: commitKey) {
                    Text("enter_chamber")
                        .padding(.horizontal, 24).padding(.vertical, 10)
                }
                .disabled(!apiKey.hasPrefix("sk-"))
                .background(apiKey.hasPrefix("sk-") ? theme.accent : theme.faded)
                .foregroundColor(theme.bg1)
                .cornerRadius(6)
                .font(.custom("Georgia", size: 15))

                Text("api_key_hint")
                    .font(.custom("Georgia", size: 11))
                    .foregroundColor(theme.faded).italic()
            }
            .padding(28)
            .background(theme.cardFill)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.cardStroke, lineWidth: 1))
        }
        .frame(maxWidth: 500)
        .padding(32)
        .onChange(of: apiKey) { service.apiKey = apiKey }
    }

    func commitKey() {
        guard apiKey.hasPrefix("sk-") else { return }
        service.apiKey = apiKey
        KeychainHelper.save(apiKey)
        apiKeySet = true
    }

    // MARK: - Translator Screen

    var translatorView: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Header
                VStack(spacing: 4) {
                    Text("⚜️").font(.system(size: isIpad ? 44 : 36))
                    Text("app_title")
                        .font(.custom("Georgia", size: isIpad ? 30 : 24)).fontWeight(.bold)
                        .foregroundColor(theme.accent)
                    Button(action: { KeychainHelper.delete(); apiKey = ""; apiKeySet = false }) {
                        Text("forget_api_key")
                            .font(.custom("Georgia", size: 11)).foregroundColor(theme.faded)
                    }
                }
                .padding(.top, 16)

                // Filter chips
                filterChipsView

                Divider().background(theme.faded.opacity(0.4))

                // Style chips
                styleChipsView

                // Input card
                inputCard

                // Error
                if let error = service.errorMessage {
                    Text("⚠️ \(error)")
                        .font(.custom("Georgia", size: 13))
                        .foregroundColor(theme.accent).italic()
                        .multilineTextAlignment(.center)
                }

                // Results — 2-column grid on iPad
                if isIpad {
                    let columns = [GridItem(.flexible()), GridItem(.flexible())]
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(service.history) { entry in
                            ResultCard(entry: entry, theme: theme, isIpad: isIpad)
                        }
                    }
                } else {
                    ForEach(service.history) { entry in
                        ResultCard(entry: entry, theme: theme, isIpad: isIpad)
                    }
                }
            }
            .padding(isIpad ? 24 : 16)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18))
                    .foregroundColor(theme.faded)
                    .padding(16)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                isPresented: $showSettings,
                defaultStyleIDsRaw: $defaultStyleIDsRaw,
                theme: theme
            )
            .onDisappear { activeStyleIDs = defaultStyleIDs }
        }
    }

    // MARK: - Filter Chips

    var filterChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                filterGroup(labelKey: "filter_language") {
                    ForEach(FilterLanguage.allCases) { f in
                        filterChip(emoji: f.emoji, labelKey: f.locKey, on: filterLanguage == f) {
                            filterLanguage = f
                        }
                    }
                }
                Divider().frame(height: 24).background(theme.faded.opacity(0.4))
                filterGroup(labelKey: "filter_gender") {
                    ForEach(FilterGender.allCases) { f in
                        filterChip(emoji: f.emoji, labelKey: f.locKey, on: filterGender == f) {
                            filterGender = f
                        }
                    }
                }
                Divider().frame(height: 24).background(theme.faded.opacity(0.4))
                filterGroup(labelKey: "filter_role") {
                    ForEach(FilterCategory.allCases) { f in
                        filterChip(emoji: f.emoji, labelKey: f.locKey, on: filterCategory == f) {
                            filterCategory = f
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    func filterGroup<Content: View>(labelKey: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 4) {
            Text(labelKey)
                .font(.custom("Georgia", size: 9))
                .kerning(1.2)
                .textCase(.uppercase)
                .foregroundColor(theme.faded.opacity(0.7))
            content()
        }
    }

    func filterChip(emoji: String, labelKey: LocalizedStringKey, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Text(emoji)
                Text(labelKey)
            }
            .font(.custom("Georgia", size: 11))
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(on ? theme.accent.opacity(0.85) : theme.chipOff)
            .foregroundColor(on ? theme.chipOnText : theme.faded)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(on ? theme.accent : theme.faded.opacity(0.4), lineWidth: 1))
        }
    }

    // MARK: - Style Chips

    var styleChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(visibleStyles) { style in
                    let on = activeStyleIDs.contains(style.id)
                    Button(action: {
                        if on { activeStyleIDs.remove(style.id) }
                        else  { activeStyleIDs.insert(style.id) }
                    }) {
                        HStack(spacing: 4) {
                            Text(style.emoji).font(.system(size: 13))
                            Text(style.label).font(.custom("Georgia", size: 12))
                        }
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(on ? theme.chipOn : theme.chipOff)
                        .foregroundColor(on ? theme.chipOnText : theme.chipOffText)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20)
                            .stroke(on ? theme.accent : theme.faded.opacity(0.5), lineWidth: 1))
                    }
                }
                if visibleStyles.isEmpty {
                    Text("no_styles_match")
                        .font(.custom("Georgia", size: 12))
                        .foregroundColor(theme.faded).italic()
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Input Card

    var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $inputText)
                .font(.custom("Georgia", size: 16))
                .foregroundColor(theme.inkDark)
                .frame(minHeight: isIpad ? 100 : 80, maxHeight: isIpad ? 160 : 120)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .focused($inputFocused)

            Divider().background(theme.faded)

            HStack {
                Text(activeStyleIDs.isEmpty ? LocalizedStringKey("select_style") : LocalizedStringKey("tap_translate"))
                    .font(.custom("Georgia", size: 12))
                    .foregroundColor(theme.faded).italic()
                Spacer()
                Button(action: translate) {
                    if service.isLoading {
                        ProgressView().tint(theme.bg1)
                            .padding(.horizontal, 20).padding(.vertical, 8)
                    } else {
                        Text("translate")
                            .padding(.horizontal, 20).padding(.vertical, 8)
                    }
                }
                .disabled(!canTranslate)
                .background(canTranslate ? theme.accent : theme.faded)
                .foregroundColor(theme.bg1)
                .cornerRadius(6)
                .font(.custom("Georgia", size: 15))
            }
        }
        .padding(16)
        .background(theme.cardFill)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.cardStroke, lineWidth: 1))
    }

    var canTranslate: Bool {
        !service.isLoading &&
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty &&
        !activeStyleIDs.isEmpty
    }

    func translate() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputFocused = false
        let styles = TranslationStyle.all.filter { activeStyleIDs.contains($0.id) }
        Task { await service.translate(text: text, styles: styles) }
        inputText = ""
    }
}

// MARK: - Result Card

struct ResultCard: View {
    let entry: TranslationEntry
    let theme: AppTheme
    let isIpad: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\"\(entry.original)\"")
                .font(.custom("Georgia", size: 13))
                .foregroundColor(theme.faded).italic()
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.rowAlt)

            Divider().background(theme.faded)

            if isIpad {
                HStack(alignment: .top, spacing: 0) {
                    columnsContent
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 0) { columnsContent }
                    VStack(alignment: .leading, spacing: 0) { columnsContent }
                }
            }
        }
        .background(theme.cardFill)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.cardStroke, lineWidth: 1))
    }

    @ViewBuilder
    var columnsContent: some View {
        ForEach(Array(entry.styles.enumerated()), id: \.element.id) { i, style in
            if i > 0 { Divider().background(theme.faded) }
            translationColumn(style: style, text: entry.results[style.id] ?? "—")
        }
    }

    func translationColumn(style: TranslationStyle, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(style.emoji) \(style.label)")
                    .font(.custom("Georgia", size: 10))
                    .kerning(1.5).textCase(.uppercase)
                    .foregroundColor(theme.accent)
                Spacer()
                Button(action: { UIPasteboard.general.string = text }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(theme.faded)
                }
            }
            Text(text)
                .font(.custom("Georgia", size: 15))
                .foregroundColor(theme.inkDark).italic()
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ContentView()
}
