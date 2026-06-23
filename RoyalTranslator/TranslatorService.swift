import Foundation
import Combine

struct TranslationEntry: Identifiable {
    let id = UUID()
    let original: String
    let shakespearean: String
    let jester: String
}

private struct TranslationResponse: Decodable {
    let shakespearean: String
    let jester: String
}

@MainActor
class TranslatorService: ObservableObject {
    @Published var history: [TranslationEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var apiKey = ""

    private let systemPrompt = """
    You are a translator specializing in two styles. For every message provided, translate it into both:

    1. SHAKESPEAREAN: Early Modern English style with thee, thou, methinks, prithee, doth, hast, etc.

    2. COURT_JESTER: Playful, entertaining, slightly dramatic German as a medieval court jester would speak. \
    Use archaic German flair and expressions like "Ei, ei!" but never use titles like "Euer Majestät".

    Respond ONLY with a raw JSON object, no markdown, no backticks, no explanation:
    {"shakespearean": "...", "jester": "..."}
    """

    func translate(text: String) async {
        isLoading = true
        errorMessage = nil

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 1000,
            "system": systemPrompt,
            "messages": [["role": "user", "content": text]]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, _) = try await URLSession.shared.data(for: request)

            // Parse Anthropic response envelope
            let envelope = try JSONDecoder().decode(AnthropicResponse.self, from: data)

            guard let rawText = envelope.content.first?.text else {
                errorMessage = "Empty response from API"
                isLoading = false
                return
            }

            // Extract JSON object from response
            guard let jsonData = extractJSON(from: rawText) else {
                errorMessage = "Could not find JSON in: \(rawText.prefix(100))"
                isLoading = false
                return
            }

            let translation = try JSONDecoder().decode(TranslationResponse.self, from: jsonData)
            let entry = TranslationEntry(original: text, shakespearean: translation.shakespearean, jester: translation.jester)
            history.insert(entry, at: 0)
            if history.count > 20 { history.removeLast() }

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func extractJSON(from text: String) -> Data? {
        // Find the first { and last } to extract JSON object
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else { return nil }
        let jsonString = String(text[start...end])
        return jsonString.data(using: .utf8)
    }
}

// MARK: - Anthropic API Response Models
private struct AnthropicResponse: Decodable {
    let content: [ContentBlock]

    struct ContentBlock: Decodable {
        let type: String
        let text: String?
    }
}
