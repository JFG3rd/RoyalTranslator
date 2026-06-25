import Foundation
import SwiftUI

// MARK: - Filter Enums

enum FilterLanguage: String, CaseIterable, Identifiable {
    case all, english, german
    var id: String { rawValue }
    var emoji: String { switch self { case .all: "🌍"; case .english: "🇬🇧"; case .german: "🇩🇪" } }
    var locKey: LocalizedStringKey {
        switch self { case .all: "filter_all"; case .english: "filter_english"; case .german: "filter_german" }
    }
}

enum FilterGender: String, CaseIterable, Identifiable {
    case all, men, women
    var id: String { rawValue }
    var emoji: String { switch self { case .all: "👥"; case .men: "♂"; case .women: "♀" } }
    var locKey: LocalizedStringKey {
        switch self { case .all: "filter_all"; case .men: "filter_men"; case .women: "filter_women" }
    }
}

enum FilterCategory: String, CaseIterable, Identifiable {
    case all, royalty, court, commonFolk, mystic, clergy
    var id: String { rawValue }
    var emoji: String {
        switch self {
        case .all: "🏰"; case .royalty: "👑"; case .court: "🎭"
        case .commonFolk: "🧑‍🌾"; case .mystic: "🔮"; case .clergy: "✝️"
        }
    }
    var locKey: LocalizedStringKey {
        switch self {
        case .all: "filter_all"; case .royalty: "filter_royalty"; case .court: "filter_court"
        case .commonFolk: "filter_folk"; case .mystic: "filter_mystic"; case .clergy: "filter_clergy"
        }
    }
}

// MARK: - Style Model

struct TranslationStyle: Identifiable, Hashable {
    let id: String
    let emoji: String
    let label: String
    let prompt: String
    let language: FilterLanguage
    let gender: FilterGender
    let category: FilterCategory

    func matches(language: FilterLanguage, gender: FilterGender, category: FilterCategory) -> Bool {
        (language == .all || self.language == language) &&
        (gender == .all || self.gender == gender) &&
        (category == .all || self.category == category)
    }

    // MARK: - All Styles

    static let all: [TranslationStyle] = [

        // ── EXISTING MEN ────────────────────────────────────────────────

        .init(id: "shakespearean", emoji: "⚜️", label: "Shakespearean",
              prompt: "SHAKESPEAREAN: Early Modern English with thee, thou, methinks, prithee, doth, hast, etc.",
              language: .english, gender: .men, category: .court),

        .init(id: "jester", emoji: "🃏", label: "Hofnarr",
              prompt: "HOFNARR: Playful dramatic German as a medieval court jester. Archaic flair, \"Ei, ei!\" — never use royal titles.",
              language: .german, gender: .men, category: .court),

        .init(id: "royal", emoji: "👑", label: "Royal Decree",
              prompt: "ROYAL_DECREE: The King addressing lowly subjects in archaic German, dripping with condescension and imperious disdain.",
              language: .german, gender: .men, category: .royalty),

        .init(id: "wizard_en", emoji: "🧙", label: "Wizard",
              prompt: "WIZARD: Cryptic ominous English prophecy. Speaks only in vague foretelling, never directly. Everything portends something.",
              language: .english, gender: .men, category: .mystic),

        .init(id: "wizard_de", emoji: "🧙", label: "Zauberer",
              prompt: "ZAUBERER: Cryptic wizard in archaic German prophecy. Ominous, vague, mystical.",
              language: .german, gender: .men, category: .mystic),

        .init(id: "drunk_en", emoji: "🍺", label: "Tavern Drunk",
              prompt: "TAVERN_DRUNK: Slurred rambling Middle English. Easily distracted, repeats himself, forgets the point, overly friendly.",
              language: .english, gender: .men, category: .commonFolk),

        .init(id: "drunk_de", emoji: "🍺", label: "Betrunkener",
              prompt: "BETRUNKENER: Same tavern drunk in slurred rambling German. Loses track mid-sentence, oddly cheerful.",
              language: .german, gender: .men, category: .commonFolk),

        .init(id: "scribe_en", emoji: "📜", label: "Royal Scribe",
              prompt: "ROYAL_SCRIBE: Over-formal English legal prose. Everything is \"heretofore\", \"whereas\", \"be it known\". Dry to the point of absurdity.",
              language: .english, gender: .men, category: .court),

        .init(id: "scribe_de", emoji: "📜", label: "Hofschreiber",
              prompt: "HOFSCHREIBER: Over-formal bureaucratic archaic German legal language. Pompously wordy, comically verbose.",
              language: .german, gender: .men, category: .court),

        .init(id: "knight_en", emoji: "🛡️", label: "Cowardly Knight",
              prompt: "COWARDLY_KNIGHT: English. Boastful declarations immediately undercut by obvious cowardice. \"I shall smite thee! ...after mine nap.\"",
              language: .english, gender: .men, category: .court),

        .init(id: "knight_de", emoji: "🛡️", label: "Feiger Ritter",
              prompt: "FEIGER_RITTER: Cowardly knight in German. Grand boasts followed immediately by fearful backpedalling.",
              language: .german, gender: .men, category: .court),

        .init(id: "monk_en", emoji: "⛪", label: "Pious Monk",
              prompt: "PIOUS_MONK: English. Everything becomes a moral lesson and prayer. Latin phrases throughout. Concerned for the listener's soul.",
              language: .english, gender: .men, category: .clergy),

        .init(id: "monk_de", emoji: "⛪", label: "Frommer Mönch",
              prompt: "FROMMER_MÖNCH: Pious monk in German with Latin sprinkled throughout. Every sentence edges toward a sermon.",
              language: .german, gender: .men, category: .clergy),

        .init(id: "peasant_en", emoji: "🧅", label: "Peasant",
              prompt: "PEASANT: Barely literate thick English dialect. Confused by anything beyond farming. Frequently mentions turnips or pigs.",
              language: .english, gender: .men, category: .commonFolk),

        .init(id: "peasant_de", emoji: "🧅", label: "Bauer",
              prompt: "BAUER: Barely literate peasant in thick German dialect. Bewildered, simple, probably thinking about the harvest.",
              language: .german, gender: .men, category: .commonFolk),

        .init(id: "nobleman_en", emoji: "🏰", label: "Scheming Nobleman",
              prompt: "SCHEMING_NOBLEMAN: Silky passive-aggressive English. Every sentence hides a veiled threat behind false courtesy.",
              language: .english, gender: .men, category: .court),

        .init(id: "nobleman_de", emoji: "🏰", label: "Schleimiger Adliger",
              prompt: "SCHLEIMIGER_ADLIGER: Scheming nobleman in archaic German. Unctuous, menacing beneath the politeness.",
              language: .german, gender: .men, category: .court),

        // ── NEW WOMEN ───────────────────────────────────────────────────

        .init(id: "queen_en", emoji: "👑", label: "The Queen",
              prompt: "THE_QUEEN: Cold commanding English. The Queen speaks with devastating precision and absolute authority. Every word is deliberate. She does not raise her voice — she does not need to.",
              language: .english, gender: .women, category: .royalty),

        .init(id: "queen_de", emoji: "👑", label: "Die Königin",
              prompt: "DIE_KÖNIGIN: Same regal queen in archaic German. Ice-cold measured authority. Every sentence lands like a verdict.",
              language: .german, gender: .women, category: .royalty),

        .init(id: "princess_en", emoji: "👸", label: "The Princess",
              prompt: "THE_PRINCESS: Romantically dramatic English. Everything is a grand tragedy or fairy tale. Poetic, slightly breathless, sees beauty and heartbreak in all things.",
              language: .english, gender: .women, category: .royalty),

        .init(id: "princess_de", emoji: "👸", label: "Die Prinzessin",
              prompt: "DIE_PRINZESSIN: Romantic princess in archaic German. Dreamy, poetic, everything is destined and deeply meaningful.",
              language: .german, gender: .women, category: .royalty),

        .init(id: "maid_en", emoji: "🧹", label: "Chambermaid",
              prompt: "CHAMBERMAID: Gossipy knowing English. Has heard everything through keyholes and seen everything from corners. Practical, slightly judgmental, raises an eyebrow at everything.",
              language: .english, gender: .women, category: .court),

        .init(id: "maid_de", emoji: "🧹", label: "Dienstmädchen",
              prompt: "DIENSTMÄDCHEN: Gossipy chambermaid in German dialect. Knows all court secrets and shares them with relish.",
              language: .german, gender: .women, category: .court),

        .init(id: "sorceress_en", emoji: "🔮", label: "Sorceress",
              prompt: "SORCERESS: Darkly knowing English. Speaks in half-threats and riddles, implies she already knows your future. Elegant and deeply unsettling.",
              language: .english, gender: .women, category: .mystic),

        .init(id: "sorceress_de", emoji: "🔮", label: "Die Hexe",
              prompt: "DIE_HEXE: Sorceress in archaic German. Mysterious, slightly threatening, speaks as if reading from a fate already written.",
              language: .german, gender: .women, category: .mystic),

        .init(id: "ladycourt_en", emoji: "🎶", label: "Lady of the Court",
              prompt: "LADY_OF_COURT: Refined flowery English. Everything is a courtly romance. Speaks in poetic flourishes, slightly breathless, finds beauty and metaphor in the mundane.",
              language: .english, gender: .women, category: .court),

        .init(id: "ladycourt_de", emoji: "🎶", label: "Die Hofdame",
              prompt: "DIE_HOFDAME: Lady of the court in elegant archaic German. Refined, poetic, sees romance in everything.",
              language: .german, gender: .women, category: .court),

        .init(id: "huntress_en", emoji: "🏹", label: "Huntress",
              prompt: "HUNTRESS: Direct fierce English. No patience for ceremony. Gets to the point immediately. Speaks like someone who would rather be in the forest. Practical and slightly impatient.",
              language: .english, gender: .women, category: .commonFolk),

        .init(id: "huntress_de", emoji: "🏹", label: "Die Jägerin",
              prompt: "DIE_JÄGERIN: Huntress in blunt archaic German. Direct, outdoorsy, impatient with pretense.",
              language: .german, gender: .women, category: .commonFolk),

        .init(id: "apothecary_en", emoji: "⚗️", label: "Apothecary",
              prompt: "APOTHECARY: Precise learned English. Measures words like ingredients. Clinical observations with a slightly ominous undertone — knows too much about what herbs can do.",
              language: .english, gender: .women, category: .mystic),

        .init(id: "apothecary_de", emoji: "⚗️", label: "Die Apothekerin",
              prompt: "DIE_APOTHEKERIN: Apothecary in archaic German. Precise, clinical, unsettlingly knowledgeable.",
              language: .german, gender: .women, category: .mystic),

        .init(id: "abbess_en", emoji: "✝️", label: "The Abbess",
              prompt: "THE_ABBESS: Authoritative firm English. Like the monk but with iron command rather than gentle piety. Manages with a velvet fist. Will pray for your soul but expects compliance.",
              language: .english, gender: .women, category: .clergy),

        .init(id: "abbess_de", emoji: "✝️", label: "Die Äbtissin",
              prompt: "DIE_ÄBTISSIN: Abbess in archaic German. Commanding pious authority. Expects obedience and receives it.",
              language: .german, gender: .women, category: .clergy),

        .init(id: "wisewoman_en", emoji: "🧶", label: "Wise Woman",
              prompt: "WISE_WOMAN: Earthy gentle English. Village elder with deep knowledge of herbs, seasons, and human nature. Speaks with quiet certainty. Says things that sound like prophecy but claims it is just common sense.",
              language: .english, gender: .women, category: .commonFolk),

        .init(id: "wisewoman_de", emoji: "🧶", label: "Die Weise Frau",
              prompt: "DIE_WEISE_FRAU: Wise woman in archaic German. Earthy, knowing, gently unsettling in her accuracy.",
              language: .german, gender: .women, category: .commonFolk),
    ]

    static let defaultIDs: Set<String> = ["shakespearean", "jester", "royal"]
}
