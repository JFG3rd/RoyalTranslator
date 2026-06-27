import Foundation
import Combine

struct TranslationEntry: Identifiable, Codable {
    let id: UUID
    let original: String
    let styles: [TranslationStyle]
    let results: [String: String]
    let date: Date

    init(original: String, styles: [TranslationStyle], results: [String: String]) {
        self.id = UUID()
        self.original = original
        self.styles = styles
        self.results = results
        self.date = Date()
    }
}

@MainActor
class TranslatorService: ObservableObject {
    @Published var history: [TranslationEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    // Composite keys: "\(entryID.uuidString):\(styleID)" — favourites individual character bubbles
    @Published var favoritedIDs: Set<String> = []

    var apiKey = ""

    // MARK: - Persistence

    private static var historyURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("translation_history.json")
    }

    private static var favoritesURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("favorites.json")
    }

    init() {
        loadHistory()
        loadFavorites()
    }

    private func loadHistory() {
        guard let data = try? Data(contentsOf: Self.historyURL),
              let decoded = try? JSONDecoder().decode([TranslationEntry].self, from: data)
        else { return }
        history = decoded
    }

    func saveHistoryPublic() { saveHistory() }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        try? data.write(to: Self.historyURL, options: .atomic)
    }

    private func loadFavorites() {
        guard let data = try? Data(contentsOf: Self.favoritesURL),
              let decoded = try? JSONDecoder().decode(Set<String>.self, from: data)
        else { return }
        favoritedIDs = decoded
    }

    private func saveFavorites() {
        guard let data = try? JSONEncoder().encode(favoritedIDs) else { return }
        try? data.write(to: Self.favoritesURL, options: .atomic)
    }

    // Key is either a composite "entryUUID:styleID" string or a bare UUID string (legacy)
    func toggleFavorite(_ key: String) {
        if favoritedIDs.contains(key) { favoritedIDs.remove(key) }
        else { favoritedIDs.insert(key) }
        saveFavorites()
    }

    // MARK: - Translation

    func translate(text: String, styles: [TranslationStyle]) async {
        guard !styles.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        let systemPrompt = buildPrompt(for: styles)
        let body: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 200 * styles.count + 200,
            "system": systemPrompt,
            "messages": [["role": "user", "content": text]]
        ]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let err = obj["error"] as? [String: Any],
                   let msg = err["message"] as? String {
                    errorMessage = "API error \(http.statusCode): \(msg)"
                } else { errorMessage = "HTTP \(http.statusCode)" }
                isLoading = false; return
            }
            let envelope = try JSONDecoder().decode(AnthropicResponse.self, from: data)
            guard let rawText = envelope.content.first?.text else {
                errorMessage = "Empty response from API"; isLoading = false; return
            }
            guard let jsonData = extractJSON(from: rawText),
                  let results = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String] else {
                errorMessage = "Could not parse response: \(rawText.prefix(120))"; isLoading = false; return
            }
            let entry = TranslationEntry(original: text, styles: styles, results: results)
            history.insert(entry, at: 0)
            if history.count > 20 { history.removeLast() }
            saveHistory()
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    private func buildPrompt(for styles: [TranslationStyle]) -> String {
        let numbered = styles.enumerated().map { i, s in "\(i + 1). \(s.prompt)" }.joined(separator: "\n\n")
        let keys = styles.map { "\"\($0.id)\": \"...\"" }.joined(separator: ", ")
        return """
        You are a style translator. Your task is to REPHRASE the user's text — preserving its exact meaning \
        and content — into each of the following styles. Do NOT answer, respond to, or comment on the text. \
        Do NOT add new information. Simply reword what was said as if that style of person had originally \
        said the same thing.

        Styles to translate into:

        \(numbered)

        Respond ONLY with a raw JSON object, no markdown, no backticks, no explanation:
        {\(keys)}
        """
    }

    private func extractJSON(from text: String) -> Data? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else { return nil }
        return String(text[start...end]).data(using: .utf8)
    }
}

private struct AnthropicResponse: Decodable {
    let content: [ContentBlock]
    struct ContentBlock: Decodable { let type: String; let text: String? }
}
