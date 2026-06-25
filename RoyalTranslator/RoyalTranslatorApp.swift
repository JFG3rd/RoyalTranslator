import SwiftUI

@main
struct RoyalTranslatorApp: App {

    init() {
        // Push version number into UserDefaults so Settings.bundle can display it
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let build   = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        UserDefaults.standard.set("\(version) (\(build))", forKey: "app_version_display")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
