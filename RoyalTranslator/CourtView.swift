import SwiftUI

struct CourtView: View {
    @EnvironmentObject var court: CourtViewModel
    let theme: AppTheme
    var sheetMode = false
    var onDismiss: (() -> Void)? = nil

    @State private var longPressedStyle: TranslationStyle? = nil

    var body: some View {
        ZStack {
            LinearGradient(colors: [theme.bg1, theme.bg2],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("🏰")
                    Text("court_title")
                        .font(.custom("Georgia", size: theme.scaled(20))).fontWeight(.bold)
                        .foregroundColor(theme.accent)
                    Spacer()
                    Text(court.activeStyleIDs.isEmpty
                         ? LocalizedStringKey("court_none")
                         : LocalizedStringKey("court_summoned \(court.activeStyleIDs.count)"))
                        .font(.custom("Georgia", size: theme.scaled(12)))
                        .foregroundColor(theme.faded).italic()
                    if sheetMode {
                        Button(action: { onDismiss?() }) {
                            Image(systemName: "xmark")
                                .foregroundColor(theme.faded)
                                .font(.system(size: theme.scaled(18)))
                                .padding(.leading, 8)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

                // Filter rows
                filterRows

                Divider().background(theme.faded.opacity(0.3)).padding(.vertical, 8)

                // Quick actions
                HStack(spacing: 16) {
                    Button(action: { court.clearAll() }) {
                        Text("court_clear_all")
                            .font(.custom("Georgia", size: theme.scaled(11)))
                            .foregroundColor(theme.faded)
                    }
                    Spacer()
                    Button(action: { court.restoreDefaults() }) {
                        Text("court_restore_defaults")
                            .font(.custom("Georgia", size: theme.scaled(11)))
                            .foregroundColor(theme.accent)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

                // Character grid
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 88, maximum: 120), spacing: 10)],
                        spacing: 10
                    ) {
                        ForEach(court.visibleStyles) { style in
                            characterCard(style)
                        }
                        if court.visibleStyles.isEmpty {
                            Text("no_styles_match")
                                .font(.custom("Georgia", size: theme.scaled(13)))
                                .foregroundColor(theme.faded).italic()
                                .gridCellColumns(3)
                                .padding(.top, 32)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, sheetMode ? 88 : 20)
                }

                // Sheet-mode summon bar
                if sheetMode {
                    summonBar
                }
            }
        }
        .font(.custom("Georgia", size: theme.scaled(14)))
        .foregroundColor(theme.inkDark)
        .popover(item: $longPressedStyle) { style in
            characterPopover(style)
        }
    }

    // MARK: - Filter rows

    var filterRows: some View {
        VStack(spacing: 6) {
            // Row 1: Category
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(FilterCategory.allCases) { cat in
                        filterPill(emoji: cat.emoji, labelKey: cat.locKey,
                                   on: court.filterCategory == cat) {
                            court.filterCategory = cat
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            // Row 2: Language + Gender
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(FilterLanguage.allCases) { lang in
                        filterPill(emoji: lang.emoji, labelKey: lang.locKey,
                                   on: court.filterLanguage == lang) {
                            court.filterLanguage = lang
                        }
                    }
                    Divider().frame(height: 22).background(theme.faded.opacity(0.4))
                    ForEach(FilterGender.allCases) { g in
                        filterPill(emoji: g.emoji, labelKey: g.locKey,
                                   on: court.filterGender == g) {
                            court.filterGender = g
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    func filterPill(emoji: String, labelKey: LocalizedStringKey, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 3) {
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

    // MARK: - Character card

    func characterCard(_ style: TranslationStyle) -> some View {
        let selected = court.activeStyleIDs.contains(style.id)
        return Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                court.toggle(style)
            }
        }) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 6) {
                    Text(style.emoji)
                        .font(.system(size: 34))
                    Text(style.label)
                        .font(.custom("Georgia", size: theme.scaled(11)))
                        .foregroundColor(theme.inkDark)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 3) {
                        Text(style.language.emoji).font(.system(size: 9))
                        Text(style.gender.emoji).font(.system(size: 9))
                    }
                    .foregroundColor(theme.faded)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12).padding(.horizontal, 6)
                .background(selected ? theme.chipOn : theme.cardFill)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selected ? theme.accent : theme.cardStroke,
                                lineWidth: selected ? 2 : 1)
                )

                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: theme.scaled(14)))
                        .foregroundColor(theme.accent)
                        .padding(5)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .onLongPressGesture { longPressedStyle = style }
    }

    // MARK: - Character popover

    func characterPopover(_ style: TranslationStyle) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(style.emoji).font(.system(size: 32))
                VStack(alignment: .leading, spacing: 2) {
                    Text(style.label)
                        .font(.custom("Georgia", size: theme.scaled(16))).fontWeight(.bold)
                        .foregroundColor(theme.accent)
                    HStack(spacing: 4) {
                        Text(style.language.emoji)
                        Text(style.language.locKey)
                        Text("·")
                        Text(style.gender.emoji)
                        Text(style.gender.locKey)
                        Text("·")
                        Text(style.category.locKey)
                    }
                    .font(.custom("Georgia", size: theme.scaled(11)))
                    .foregroundColor(theme.faded)
                }
            }
        }
        .padding(20)
        .background(theme.cardFill)
        .presentationCompactAdaptation(.popover)
    }

    // MARK: - Sheet summon bar

    var summonBar: some View {
        HStack(spacing: 12) {
            Button(action: { onDismiss?() }) {
                Text("court_dismiss")
                    .font(.custom("Georgia", size: theme.scaled(14)))
                    .foregroundColor(theme.faded)
                    .padding(.horizontal, 20).padding(.vertical, 11)
                    .background(theme.chipOff)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.faded.opacity(0.4), lineWidth: 1))
            }
            Button(action: { onDismiss?() }) {
                HStack(spacing: 6) {
                    Text(court.activeStyleIDs.isEmpty
                         ? LocalizedStringKey("court_summon_none")
                         : LocalizedStringKey("court_summon \(court.activeStyleIDs.count)"))
                    Image(systemName: "chevron.right")
                }
                .font(.custom("Georgia", size: theme.scaled(14)))
                .foregroundColor(theme.bg1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(court.activeStyleIDs.isEmpty ? theme.faded : theme.accent)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(theme.bg1.opacity(0.95))
        .overlay(alignment: .top) {
            Divider().background(theme.cardStroke)
        }
    }
}

// MARK: - Spring scale button style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
