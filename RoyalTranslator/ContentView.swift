import SwiftUI

struct ContentView: View {
    @StateObject private var service = TranslatorService()
    @State private var inputText = ""
    @State private var apiKey = ""
    @State private var apiKeySet = false
    @State private var showAPIKey = false
    @State private var showSettings = false
    @FocusState private var inputFocused: Bool

    let inkDark = Color(red: 0.1, green: 0.07, blue: 0.035)
    let vellum = Color(red: 0.96, green: 0.93, blue: 0.84)
    let parchment = Color(red: 0.93, green: 0.88, blue: 0.72)
    let accent = Color(red: 0.48, green: 0.23, blue: 0.12)
    let faded = Color(red: 0.62, green: 0.55, blue: 0.43)

    var body: some View {
        ZStack {
            LinearGradient(colors: [vellum, parchment], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            if !apiKeySet {
                keyEntryView
            } else {
                translatorView
            }
        }
        .font(.custom("Georgia", size: 16))
        .foregroundColor(inkDark)
        .onAppear {
            if let savedKey = KeychainHelper.load(), savedKey.hasPrefix("sk-") {
                apiKey = savedKey
                service.apiKey = savedKey
                apiKeySet = true
            }
        }
    }

    // MARK: - API Key Screen
    var keyEntryView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("⚜️").font(.system(size: 40))
                Text("The Royal Translator")
                    .font(.custom("Georgia", size: 26))
                    .fontWeight(.bold)
                    .foregroundColor(accent)
                Text("Shakespearean · Court Jester German")
                    .font(.custom("Georgia", size: 13))
                    .foregroundColor(faded)
                    .italic()
            }

            VStack(spacing: 16) {
                Text("Enter your Anthropic API key to begin.\nIt is stored only in device memory.")
                    .font(.custom("Georgia", size: 14))
                    .foregroundColor(faded)
                    .italic()
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
                    .onSubmit {
                        if apiKey.hasPrefix("sk-") {
                            apiKeySet = true
                            service.apiKey = apiKey
                            KeychainHelper.save(apiKey)
                        }
                    }

                    Button(action: { showAPIKey.toggle() }) {
                        Image(systemName: showAPIKey ? "eye.slash" : "eye")
                            .foregroundColor(faded)
                            .padding(.vertical, 10)
                            .padding(.trailing, 6)
                    }

                    Button(action: {
                        if let str = UIPasteboard.general.string {
                            apiKey = str
                        }
                    }) {
                        Image(systemName: "doc.on.clipboard")
                            .foregroundColor(faded)
                            .padding(.vertical, 10)
                            .padding(.trailing, 10)
                    }
                }
                .background(Color.white.opacity(0.6))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(faded, lineWidth: 1))

                Button("Enter the Chamber") {
                    apiKeySet = true
                    service.apiKey = apiKey
                    KeychainHelper.save(apiKey)
                }
                .disabled(!apiKey.hasPrefix("sk-"))
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(apiKey.hasPrefix("sk-") ? accent : faded)
                .foregroundColor(vellum)
                .cornerRadius(6)
                .font(.custom("Georgia", size: 15))

                Text("Get your key at console.anthropic.com")
                    .font(.custom("Georgia", size: 11))
                    .foregroundColor(faded)
                    .italic()
            }
            .padding(28)
            .background(Color.white.opacity(0.4))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(faded, lineWidth: 1))
        }
        .padding(32)
        .onChange(of: apiKey) { service.apiKey = apiKey }
    }

    // MARK: - Translator Screen
    var translatorView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 4) {
                    Text("⚜️").font(.system(size: 36))
                    Text("The Royal Translator")
                        .font(.custom("Georgia", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(accent)
                    Text("Shakespearean · Court Jester German")
                        .font(.custom("Georgia", size: 12))
                        .foregroundColor(faded)
                        .italic()
                    Button("Forget API Key") {
                        KeychainHelper.delete()
                        apiKey = ""
                        apiKeySet = false
                    }
                    .font(.custom("Georgia", size: 11))
                    .foregroundColor(faded)
                }
                .padding(.top, 16)

                // Input card
                VStack(alignment: .leading, spacing: 12) {
                    TextEditor(text: $inputText)
                        .font(.custom("Georgia", size: 16))
                        .foregroundColor(inkDark)
                        .frame(minHeight: 80, maxHeight: 120)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .focused($inputFocused)

                    Divider().background(faded)

                    HStack {
                        Text("Tap Translate or press Return")
                            .font(.custom("Georgia", size: 12))
                            .foregroundColor(faded)
                            .italic()
                        Spacer()
                        Button(action: translate) {
                            if service.isLoading {
                                ProgressView()
                                    .tint(vellum)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                            } else {
                                Text("Translate")
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                            }
                        }
                        .disabled(service.isLoading || inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                        .background(service.isLoading || inputText.isEmpty ? faded : accent)
                        .foregroundColor(vellum)
                        .cornerRadius(6)
                        .font(.custom("Georgia", size: 15))
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.4))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(faded, lineWidth: 1))

                // Error
                if let error = service.errorMessage {
                    Text("⚠️ \(error)")
                        .font(.custom("Georgia", size: 13))
                        .foregroundColor(accent)
                        .italic()
                        .multilineTextAlignment(.center)
                }

                // Results
                ForEach(service.history) { entry in
                    ResultCard(entry: entry, accent: accent, faded: faded, inkDark: inkDark)
                }
            }
            .padding(16)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 18))
                    .foregroundColor(faded)
                    .padding(16)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(
                isPresented: $showSettings,
                accent: accent, faded: faded,
                vellum: vellum, inkDark: inkDark,
                parchment: parchment
            )
        }
    }

    func translate() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputFocused = false
        Task { await service.translate(text: text) }
        inputText = ""
    }
}

// MARK: - Result Card
struct ResultCard: View {
    let entry: TranslationEntry
    let accent: Color
    let faded: Color
    let inkDark: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Original
            Text("\"\(entry.original)\"")
                .font(.custom("Georgia", size: 13))
                .foregroundColor(faded)
                .italic()
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.06))

            Divider().background(faded)

            // Two columns on iPad, stacked on iPhone
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 0) {
                    translationColumn(label: "⚜ Shakespearean", text: entry.shakespearean)
                    Divider().background(faded)
                    translationColumn(label: "🃏 Hofnarr", text: entry.jester)
                }
                VStack(alignment: .leading, spacing: 0) {
                    translationColumn(label: "⚜ Shakespearean", text: entry.shakespearean)
                    Divider().background(faded)
                    translationColumn(label: "🃏 Hofnarr", text: entry.jester)
                }
            }
        }
        .background(Color.white.opacity(0.3))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(faded, lineWidth: 1))
    }

    func translationColumn(label: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.custom("Georgia", size: 10))
                .kerning(1.5)
                .textCase(.uppercase)
                .foregroundColor(accent)
            Text(text)
                .font(.custom("Georgia", size: 15))
                .foregroundColor(inkDark)
                .italic()
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ContentView()
}
