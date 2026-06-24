import Foundation
import Combine

struct TranslationEntry: Identifiable {
    let id = UUID()
    let original: String
    let styles: [TranslationStyle]
    let results: [String: String]
}

@MainActor
class TranslatorService: ObservableObject {
    @Published var history: [TranslationEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var apiKey = ""

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
                } else {
                    errorMessage = "HTTP \(http.statusCode)"
                }
                isLoading = false
                return
            }

            let envelope = try JSONDecoder().decode(AnthropicResponse.self, from: data)
            guard let rawText = envelope.content.first?.text else {
                errorMessage = "Empty response from API"
                isLoading = false
                return
            }

            guard let jsonData = extractJSON(from: rawText),
                  let results = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String] else {
                errorMessage = "Could not parse response: \(rawText.prefix(120))"
                isLoading = false
                return
            }

            let entry = TranslationEntry(original: text, styles: styles, results: results)
            history.insert(entry, at: 0)
            if history.count > 20 { history.removeLast() }

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func buildPrompt(for styles: [TranslationStyle]) -> String {
        let numbered = styles.enumerated().map { i, s in "\(i + 1). \(s.prompt)" }.joined(separator: "\n\n")
        let keys = styles.map { "\"\($0.id)\": \"...\"" }.joined(separator: ", ")
        return """
        You are a translator specializing in multiple medieval and fantasy styles. \
        For every message, translate it into each of the following styles:

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
    struct ContentBlock: Decodable {
        let type: String
        let text: String?
    }
}
