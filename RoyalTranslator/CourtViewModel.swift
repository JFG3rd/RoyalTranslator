import SwiftUI
import Combine

@MainActor
class CourtViewModel: ObservableObject {
    @Published var activeStyleIDs: Set<String>
    @Published var filterLanguage: FilterLanguage = .all
    @Published var filterGender: FilterGender = .all
    @Published var filterCategory: FilterCategory = .all

    private let defaultsKey = "defaultStyleIDs"

    var defaultStyleIDs: Set<String> {
        let raw = UserDefaults.standard.string(forKey: defaultsKey) ?? ""
        let ids = Set(raw.split(separator: ",").map(String.init))
        return ids.isEmpty ? TranslationStyle.defaultIDs : ids
    }

    init() {
        activeStyleIDs = {
            let raw = UserDefaults.standard.string(forKey: "defaultStyleIDs") ?? ""
            let ids = Set(raw.split(separator: ",").map(String.init))
            return ids.isEmpty ? TranslationStyle.defaultIDs : ids
        }()
    }

    var visibleStyles: [TranslationStyle] {
        TranslationStyle.all.filter {
            $0.matches(language: filterLanguage, gender: filterGender, category: filterCategory)
        }
    }

    var activeStyles: [TranslationStyle] {
        TranslationStyle.all.filter { activeStyleIDs.contains($0.id) }
    }

    func toggle(_ style: TranslationStyle) {
        if activeStyleIDs.contains(style.id) {
            activeStyleIDs.remove(style.id)
        } else {
            activeStyleIDs.insert(style.id)
        }
    }

    func clearAll() {
        activeStyleIDs = []
    }

    func restoreDefaults() {
        activeStyleIDs = defaultStyleIDs
    }

    func saveAsDefaults() {
        UserDefaults.standard.set(activeStyleIDs.joined(separator: ","), forKey: defaultsKey)
    }
}
