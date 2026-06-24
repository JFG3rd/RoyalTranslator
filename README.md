# ⚜️ The Royal Translator

A native iOS app that rephrases any text into a collection of medieval and fantasy character styles — powered by the Anthropic Claude API.

---

## What it does

Type anything. The Royal Translator rewrites it as if spoken by characters from a medieval court — preserving your exact meaning but transforming the voice entirely.

**Included styles:**

| Style | Language | Character |
|---|---|---|
| ⚜️ Shakespearean | English | Early Modern English — thee, thou, methinks, prithee |
| 🃏 Hofnarr | German | The court jester — playful, archaic, "Ei, ei!" |
| 👑 Royal Decree | German | The King addressing wretched lowly subjects |
| 🧙 Wizard / Zauberer | EN + DE | Cryptic prophecy — everything portends something |
| 🍺 Tavern Drunk / Betrunkener | EN + DE | Slurred, rambling, very friendly, forgets his point |
| 📜 Royal Scribe / Hofschreiber | EN + DE | Over-formal legal prose, comically verbose |
| 🛡️ Cowardly Knight / Feiger Ritter | EN + DE | Grand boasts immediately undercut by obvious fear |
| ⛪ Pious Monk / Frommer Mönch | EN + DE | Everything becomes a sermon, Latin sprinkled throughout |
| 🧅 Peasant / Bauer | EN + DE | Barely literate, bewildered, concerned about turnips |
| 🏰 Scheming Nobleman / Schleimiger Adliger | EN + DE | Silky passive-aggressive, every sentence hides a threat |

---

## Features

- **Style chips** — select exactly which styles to translate into per session
- **Saved defaults** — set your preferred styles in Settings, pre-selected every launch
- **Copy button** on every translation — paste directly into any other app
- **Dual app icons** — light (burgundy/gold) and dark (black/gold), switchable in Settings
- **Secure API key storage** — your Anthropic key is saved in the iOS Keychain
- Works on iPhone and iPad

---

## Requirements

- iOS 17 or later
- An [Anthropic API key](https://console.anthropic.com) (the app stores it locally on your device — never sent anywhere except the Anthropic API)

---

## Getting started

1. Clone the repo and open `RoyalTranslator.xcodeproj` in Xcode
2. Set your development team in **Signing & Capabilities**
3. Build and run on your device or simulator
4. Enter your Anthropic API key on first launch

---

## Architecture

| File | Purpose |
|---|---|
| `TranslationStyle.swift` | All 17 style definitions with prompts |
| `TranslatorService.swift` | Builds dynamic prompts, calls Anthropic API, parses responses |
| `ContentView.swift` | Main UI — key entry, style chips, input, result cards |
| `SettingsView.swift` | Default style toggles, app icon picker |
| `KeychainHelper.swift` | Secure API key storage and retrieval |

The app calls the Anthropic Messages API directly via `URLSession` with no third-party dependencies.

---

## License

MIT
