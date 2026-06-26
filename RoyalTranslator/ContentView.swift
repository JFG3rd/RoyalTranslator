import SwiftUI

struct ContentView: View {
    @StateObject private var service = TranslatorService()
    @State private var inputText = ""
    @State private var apiKey = ""
    @State private var apiKeySet = false
    @State private var showAPIKey = false
    @State private var showSettings = false
    @State private var showTutorial = false
    @State private var translateDidSucceed = false
    @AppStorage("hideTutorial") private var hideTutorial = false
    @State private var showFavoritesOnly = false
    @FocusState private var inputFocused: Bool

    @AppStorage("defaultStyleIDs") private var defaultStyleIDsRaw: String =
        TranslationStyle.defaultIDs.joined(separator: ",")
    @AppStorage("fontSizeBase") private var fontSizeBase: Double = 17

    @State private var activeStyleIDs: Set<String> = TranslationStyle.defaultIDs
    @State private var filterLanguage: FilterLanguage = .all
    @State private var filterGender: FilterGender = .all
    @State private var filterCategory: FilterCategory = .all

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var hSizeClass

    var theme: AppTheme { AppTheme(scheme: colorScheme, base: CGFloat(fontSizeBase)) }
    var isIpad: Bool { hSizeClass == .regular }

    var defaultStyleIDs: Set<String> {
        Set(defaultStyleIDsRaw.split(separator: ",").map(String.init))
    }

    var visibleStyles: [TranslationStyle] {
        TranslationStyle.all.filter {
            $0.matches(language: filterLanguage, gender: filterGender, category: filterCategory)
        }
    }

    var displayedHistory: [TranslationEntry] {
        showFavoritesOnly
            ? service.history.filter { service.favoritedIDs.contains($0.id) }
            : service.history
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
        .font(.custom("Georgia", size: theme.scaled(16)))
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
        UserDefaults.standard.register(defaults: [
            "clear_api_key": false,
            "persist_api_key": false,
            "fontSizeBase": 17.0
        ])
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
                // Title — intentionally not scaled
                Text("app_title")
                    .font(.custom("Georgia", size: 26)).fontWeight(.bold)
                    .foregroundColor(theme.accent)
                Text("app_subtitle")
                    .font(.custom("Georgia", size: theme.scaled(13)))
                    .foregroundColor(theme.faded).italic()
            }

            VStack(spacing: 16) {
                Text("api_key_prompt")
                    .font(.custom("Georgia", size: theme.scaled(14)))
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
                .font(.custom("Georgia", size: theme.scaled(15)))

                Text("api_key_hint")
                    .font(.custom("Georgia", size: theme.scaled(11)))
                    .foregroundColor(theme.faded).italic()

                Divider().background(theme.faded.opacity(0.3))

                Toggle(isOn: $hideTutorial) {
                    Text("tutorial_hide")
                        .font(.custom("Georgia", size: theme.scaled(12)))
                        .foregroundColor(theme.faded)
                }
                .tint(theme.accent)
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
        if !hideTutorial { showTutorial = true }
    }

    // MARK: - Translator Screen

    var translatorView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 20) {

                    // Header
                    VStack(spacing: 4) {
                        Text("⚜️").font(.system(size: isIpad ? 44 : 36))
                        // Title — intentionally not scaled
                        Text("app_title")
                            .font(.custom("Georgia", size: isIpad ? 30 : 24)).fontWeight(.bold)
                            .foregroundColor(theme.accent)
                    }
                    .padding(.top, 16)

                    // Filter chips
                    filterChipsView

                    Divider().background(theme.faded.opacity(0.4))

                    // Style chips
                    styleChipsView

                    // Input card — scroll anchor
                    inputCard
                        .id("inputCard")

                    // Error
                    if let error = service.errorMessage {
                        Text("⚠️ \(error)")
                            .font(.custom("Georgia", size: theme.scaled(13)))
                            .foregroundColor(theme.accent).italic()
                            .multilineTextAlignment(.center)
                    }

                    // Favorites toggle
                    if !service.history.isEmpty {
                        HStack {
                            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showFavoritesOnly.toggle() } }) {
                                HStack(spacing: 5) {
                                    Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                                    Text(showFavoritesOnly ? LocalizedStringKey("filter_all") : "♥")
                                }
                                .font(.custom("Georgia", size: theme.scaled(12)))
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(showFavoritesOnly ? theme.accent.opacity(0.15) : theme.chipOff)
                                .foregroundColor(showFavoritesOnly ? theme.accent : theme.faded)
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20)
                                    .stroke(showFavoritesOnly ? theme.accent : theme.faded.opacity(0.5), lineWidth: 1))
                            }
                            Spacer()
                            Text("\(displayedHistory.count)")
                                .font(.custom("Georgia", size: theme.scaled(11)))
                                .foregroundColor(theme.faded)
                        }
                    }

                    // Results
                    if isIpad {
                        let columns = [GridItem(.flexible()), GridItem(.flexible())]
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(displayedHistory) { entry in
                                ResultCard(
                                    entry: entry, theme: theme, isIpad: isIpad,
                                    isFavorited: service.favoritedIDs.contains(entry.id),
                                    onTapOriginal: { text in repopulate(text, proxy: proxy) },
                                    onToggleFavorite: { service.toggleFavorite(entry.id) }
                                )
                            }
                        }
                    } else {
                        ForEach(displayedHistory) { entry in
                            ResultCard(
                                entry: entry, theme: theme, isIpad: isIpad,
                                isFavorited: service.favoritedIDs.contains(entry.id),
                                onTapOriginal: { text in repopulate(text, proxy: proxy) },
                                onToggleFavorite: { service.toggleFavorite(entry.id) }
                            )
                        }
                    }
                }
                .padding(isIpad ? 24 : 16)
            }
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 4) {
                    Button(action: { showTutorial = true }) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: theme.scaled(18)))
                            .foregroundColor(theme.faded)
                            .padding(.vertical, 16)
                            .padding(.leading, 16)
                    }
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: theme.scaled(18)))
                            .foregroundColor(theme.faded)
                            .padding(16)
                    }
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
            .sheet(isPresented: $showTutorial) {
                TutorialView(isPresented: $showTutorial, theme: theme)
            }
        }
    }

    private func repopulate(_ text: String, proxy: ScrollViewProxy) {
        inputText = text
        withAnimation(.easeInOut(duration: 0.35)) {
            proxy.scrollTo("inputCard", anchor: .top)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            inputFocused = true
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
                .font(.custom("Georgia", size: theme.scaled(9)))
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
            .font(.custom("Georgia", size: theme.scaled(11)))
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
                            Text(style.emoji).font(.system(size: theme.scaled(13)))
                            Text(style.label).font(.custom("Georgia", size: theme.scaled(12)))
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
                        .font(.custom("Georgia", size: theme.scaled(12)))
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
                .font(.custom("Georgia", size: theme.scaled(16)))
                .foregroundColor(theme.inkDark)
                .frame(minHeight: isIpad ? 100 : 80, maxHeight: isIpad ? 160 : 120)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .focused($inputFocused)

            Divider().background(theme.faded)

            HStack {
                Text(activeStyleIDs.isEmpty ? LocalizedStringKey("select_style") : LocalizedStringKey("tap_translate"))
                    .font(.custom("Georgia", size: theme.scaled(12)))
                    .foregroundColor(theme.faded).italic()
                Spacer()
                Button(action: translate) {
                    Group {
                        if service.isLoading {
                            ProgressView().tint(theme.bg1)
                        } else if translateDidSucceed {
                            Image(systemName: "checkmark")
                        } else {
                            Text("translate")
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 8)
                }
                .disabled(!canTranslate)
                .background(translateDidSucceed ? theme.accent.opacity(0.7) : (canTranslate ? theme.accent : theme.faded))
                .foregroundColor(theme.bg1)
                .cornerRadius(6)
                .font(.custom("Georgia", size: theme.scaled(15)))
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: translateDidSucceed)
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
        Task {
            await service.translate(text: text, styles: styles)
            if service.errorMessage == nil {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                    translateDidSucceed = true
                }
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                withAnimation { translateDidSucceed = false }
            }
        }
    }
}

// MARK: - Result Card

struct ResultCard: View {
    let entry: TranslationEntry
    let theme: AppTheme
    let isIpad: Bool
    var isFavorited: Bool = false
    var onTapOriginal: ((String) -> Void)? = nil
    var onToggleFavorite: (() -> Void)? = nil

    @State private var headerTapped = false
    @State private var heartScale: CGFloat = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Original text header — tappable area left, icons right (siblings, no overlay)
            HStack(spacing: 0) {
                Text("\"\(entry.original)\"")
                    .font(.custom("Georgia", size: theme.scaled(13)))
                    .foregroundColor(theme.faded).italic()
                    .padding(.vertical, 10)
                    .padding(.leading, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard onTapOriginal != nil else { return }
                        withAnimation(.easeIn(duration: 0.1)) { headerTapped = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            withAnimation(.easeOut(duration: 0.2)) { headerTapped = false }
                        }
                        onTapOriginal?(entry.original)
                    }
                    .layoutPriority(1)

                HStack(spacing: 10) {
                    if onTapOriginal != nil {
                        Image(systemName: "arrow.uturn.left")
                            .font(.system(size: theme.scaled(12)))
                            .foregroundColor(theme.faded.opacity(0.5))
                    }
                    Button(action: {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { heartScale = 1.45 }
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.55).delay(0.15)) { heartScale = 1.0 }
                        onToggleFavorite?()
                    }) {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .font(.system(size: theme.scaled(16)))
                            .foregroundColor(isFavorited ? theme.accent : theme.faded.opacity(0.55))
                            .scaleEffect(heartScale)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.trailing, 10)
                .padding(.leading, 6)
            }
            .background(headerTapped ? theme.accent.opacity(0.18) : theme.rowAlt)
            .animation(.easeOut(duration: 0.25), value: headerTapped)

            Divider().background(theme.faded)

            if isIpad {
                HStack(alignment: .top, spacing: 0) { columnsContent }
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
                    .font(.custom("Georgia", size: theme.scaled(10)))
                    .kerning(1.5).textCase(.uppercase)
                    .foregroundColor(theme.accent)
                Spacer()
                Button(action: { UIPasteboard.general.string = text }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: theme.scaled(12)))
                        .foregroundColor(theme.faded)
                }
            }
            Text(text)
                .font(.custom("Georgia", size: theme.scaled(15)))
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
