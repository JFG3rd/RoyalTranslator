import SwiftUI

struct DispatchView: View {
    @EnvironmentObject var court: CourtViewModel
    @EnvironmentObject var service: TranslatorService
    let theme: AppTheme

    @State private var inputText = ""
    @State private var translateDidSucceed = false
    @State private var showCourtSheet = false
    @State private var showTutorial = false
    @FocusState private var inputFocused: Bool

    @AppStorage("hideTutorial") private var hideTutorial = false

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [theme.bg1, theme.bg2],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Nav bar
                navBar

                Divider().background(theme.faded.opacity(0.3))

                // Conversation scroll
                conversationArea

                // Pinned input bar sits above keyboard
            }

            // Pinned input bar
            inputBar
                .background(theme.bg1.opacity(0.97))
                .overlay(alignment: .top) { Divider().background(theme.cardStroke) }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .sheet(isPresented: $showCourtSheet) {
            CourtView(theme: theme, sheetMode: true) { showCourtSheet = false }
                .environmentObject(court)
        }
        .sheet(isPresented: $showTutorial) {
            TutorialView(isPresented: $showTutorial, theme: theme)
        }
    }

    // MARK: - Nav bar

    var navBar: some View {
        HStack {
            HStack(spacing: 6) {
                Text("⚜️").font(.system(size: 20))
                Text("app_title")
                    .font(.custom("Georgia", size: theme.scaled(17))).fontWeight(.bold)
                    .foregroundColor(theme.accent)
            }
            Spacer()
            Button(action: { showTutorial = true }) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: theme.scaled(18)))
                    .foregroundColor(theme.faded)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Conversation area

    var conversationArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    if service.history.isEmpty && !service.isLoading {
                        emptyState
                            .padding(.top, 60)
                    }

                    ForEach(service.history.reversed()) { entry in
                        VStack(spacing: 8) {
                            UserBubble(text: entry.original, theme: theme) {
                                inputText = entry.original
                                inputFocused = true
                                withAnimation {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }

                            ForEach(entry.styles) { style in
                                let favKey = "\(entry.id.uuidString):\(style.id)"
                                CharacterBubble(
                                    style: style,
                                    text: entry.results[style.id] ?? "—",
                                    theme: theme,
                                    isFavorited: service.favoritedIDs.contains(favKey),
                                    onToggleFavorite: { service.toggleFavorite(favKey) }
                                )
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                            }
                        }
                        .id(entry.id)
                    }

                    if service.isLoading {
                        TypingBubble(
                            activeEmojis: court.activeStyles.map(\.emoji),
                            theme: theme
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                    }

                    if let error = service.errorMessage {
                        errorBanner(error)
                    }

                    Color.clear.frame(height: 80).id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .onChange(of: service.history.count) {
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: service.isLoading) {
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Empty state

    var emptyState: some View {
        VStack(spacing: 16) {
            Text("⚜️").font(.system(size: 48))
            Text("dispatch_empty")
                .font(.custom("Georgia", size: theme.scaled(15))).italic()
                .foregroundColor(theme.faded)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }

    // MARK: - Error banner

    func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(theme.accent)
            Text(message)
                .font(.custom("Georgia", size: theme.scaled(13))).italic()
                .foregroundColor(theme.accent)
            Spacer()
            Button(action: { service.errorMessage = nil }) {
                Image(systemName: "xmark")
                    .font(.system(size: theme.scaled(12)))
                    .foregroundColor(theme.faded)
            }
        }
        .padding(12)
        .background(theme.accent.opacity(0.1))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.accent.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Pinned input bar

    var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Court badge
            Button(action: { showCourtSheet = true }) {
                HStack(spacing: 4) {
                    if let first = court.activeStyles.first {
                        Text(first.emoji).font(.system(size: 16))
                    } else {
                        Image(systemName: "person.3")
                            .font(.system(size: 14))
                    }
                    if court.activeStyleIDs.count > 1 {
                        Text("+\(court.activeStyleIDs.count - 1)")
                            .font(.custom("Georgia", size: theme.scaled(11)))
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(court.activeStyleIDs.isEmpty ? theme.faded.opacity(0.2) : theme.chipOn)
                .foregroundColor(court.activeStyleIDs.isEmpty ? theme.faded : theme.chipOnText)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20)
                    .stroke(court.activeStyleIDs.isEmpty ? theme.faded.opacity(0.4) : theme.accent, lineWidth: 1))
            }

            // Text input
            ZStack(alignment: .topLeading) {
                if inputText.isEmpty {
                    Text("dispatch_placeholder")
                        .font(.custom("Georgia", size: theme.scaled(15))).italic()
                        .foregroundColor(theme.faded.opacity(0.6))
                        .padding(.horizontal, 4)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $inputText)
                    .font(.custom("Georgia", size: theme.scaled(15)))
                    .foregroundColor(theme.inkDark)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($inputFocused)
                    .frame(minHeight: 36, maxHeight: 100)
            }
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(theme.inputFill)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(theme.cardStroke, lineWidth: 1))

            // Send button
            Button(action: translate) {
                Group {
                    if service.isLoading {
                        ProgressView().tint(.white).scaleEffect(0.8)
                    } else if translateDidSucceed {
                        Image(systemName: "checkmark").fontWeight(.bold)
                    } else {
                        Image(systemName: "arrow.up").fontWeight(.bold)
                    }
                }
                .font(.system(size: theme.scaled(15)))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(canTranslate ? theme.accent : theme.faded.opacity(0.4))
                .clipShape(Circle())
            }
            .disabled(!canTranslate)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: translateDidSucceed)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .padding(.bottom, 4)
    }

    // MARK: - Translation

    var canTranslate: Bool {
        !service.isLoading &&
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty &&
        !court.activeStyleIDs.isEmpty
    }

    func translate() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputFocused = false
        let styles = court.activeStyles
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
