import SwiftUI

@main
struct RoyalTranslatorApp: App {

    @StateObject private var service = TranslatorService()
    @StateObject private var court = CourtViewModel()
    @State private var apiKeySet = false
    @State private var apiKey = ""
    @AppStorage("hideTutorial") private var hideTutorial = false
    @AppStorage("use_classic_ui") private var useClassicUI = false

    init() {
        KeychainHelper.wipeIfReinstalled()
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let build   = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        UserDefaults.standard.set("\(version) (\(build))", forKey: "app_version_display")
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if useClassicUI {
                    // Classic single-scroll layout — self-contained key entry
                    ContentView()
                        .environmentObject(service)
                } else {
                    // Court Dispatch tab bar layout
                    if apiKeySet {
                        RoyalTabView()
                            .environmentObject(service)
                            .environmentObject(court)
                    } else {
                        KeyEntryView(
                            apiKey: $apiKey,
                            hideTutorial: $hideTutorial,
                            onCommit: { key in
                                service.apiKey = key
                                KeychainHelper.save(key)
                                apiKeySet = true
                            }
                        )
                    }
                }
            }
            .onAppear {
                handleSettingsBundleFlags()
                if let saved = KeychainHelper.load(), saved.hasPrefix("sk-") {
                    apiKey = saved
                    service.apiKey = saved
                    apiKeySet = true
                }
            }
        }
    }

    private func handleSettingsBundleFlags() {
        UserDefaults.standard.register(defaults: [
            "clear_api_key": false,
            "persist_api_key": false,
            "fontSizeBase": 17.0,
            "use_classic_ui": false
        ])
        if UserDefaults.standard.bool(forKey: "clear_api_key") {
            KeychainHelper.delete()
            UserDefaults.standard.set(false, forKey: "clear_api_key")
            apiKeySet = false
        }
    }
}

// MARK: - Key Entry Screen (moved out of ContentView)

struct KeyEntryView: View {
    @Binding var apiKey: String
    @Binding var hideTutorial: Bool
    let onCommit: (String) -> Void

    @State private var showAPIKey = false
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("fontSizeBase") private var fontSizeBase: Double = 17

    var theme: AppTheme { AppTheme(scheme: colorScheme, base: CGFloat(fontSizeBase)) }

    var body: some View {
        ZStack {
            LinearGradient(colors: [theme.bg1, theme.bg2],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 6) {
                    Text("⚜️").font(.system(size: 40))
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
        }
        .font(.custom("Georgia", size: theme.scaled(16)))
        .foregroundColor(theme.inkDark)
    }

    func commitKey() {
        guard apiKey.hasPrefix("sk-") else { return }
        onCommit(apiKey)
    }
}
