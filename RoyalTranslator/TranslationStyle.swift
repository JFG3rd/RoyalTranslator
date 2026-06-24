import Foundation

struct TranslationStyle: Identifiable, Hashable {
    let id: String
    let emoji: String
    let label: String
    let prompt: String

    static let all: [TranslationStyle] = [
        .init(id: "shakespearean", emoji: "⚜️", label: "Shakespearean",
              prompt: "SHAKESPEAREAN: Early Modern English with thee, thou, methinks, prithee, doth, hast, etc."),

        .init(id: "jester", emoji: "🃏", label: "Hofnarr",
              prompt: "HOFNARR: Playful, dramatic German as a medieval court jester. Archaic flair, expressions like \"Ei, ei!\" — never use royal titles."),

        .init(id: "royal", emoji: "👑", label: "Royal Decree",
              prompt: "ROYAL_DECREE: The King addressing lowly subjects in archaic German, dripping with condescension and imperious disdain."),

        .init(id: "wizard_en", emoji: "🧙", label: "Wizard",
              prompt: "WIZARD: Cryptic, ominous English prophecy. Speaks only in vague foretelling, never directly. Everything portends something."),

        .init(id: "wizard_de", emoji: "🧙", label: "Zauberer",
              prompt: "ZAUBERER: Same cryptic wizard style but in archaic German prophecy. Ominous, vague, mystical."),

        .init(id: "drunk_en", emoji: "🍺", label: "Tavern Drunk",
              prompt: "TAVERN_DRUNK: Slurred, rambling Middle English. Easily distracted, repeats himself, forgets the point, overly friendly."),

        .init(id: "drunk_de", emoji: "🍺", label: "Betrunkener",
              prompt: "BETRUNKENER: Same tavern drunk style in slurred, rambling German. Loses track mid-sentence, oddly cheerful."),

        .init(id: "scribe_en", emoji: "📜", label: "Royal Scribe",
              prompt: "ROYAL_SCRIBE: Over-formal English legal prose. Everything is \"heretofore\", \"whereas\", \"be it known\", \"the aforementioned party\". Dry to the point of absurdity."),

        .init(id: "scribe_de", emoji: "📜", label: "Hofschreiber",
              prompt: "HOFSCHREIBER: Same over-formal bureaucratic style in archaic German legal language. Pompously wordy, comically verbose."),

        .init(id: "knight_en", emoji: "🛡️", label: "Cowardly Knight",
              prompt: "COWARDLY_KNIGHT: English. Boastful declarations of bravery immediately undercut by obvious cowardice. \"I shall smite thee! ...after mine nap.\""),

        .init(id: "knight_de", emoji: "🛡️", label: "Feiger Ritter",
              prompt: "FEIGER_RITTER: Same cowardly knight in German. Grand boasts followed immediately by fearful backpedalling."),

        .init(id: "monk_en", emoji: "⛪", label: "Pious Monk",
              prompt: "PIOUS_MONK: English. Everything becomes a moral lesson and prayer. Sprinkles Latin phrases throughout. Deeply concerned for the listener's immortal soul."),

        .init(id: "monk_de", emoji: "⛪", label: "Frommer Mönch",
              prompt: "FROMMER_MÖNCH: Same pious monk in German, with Latin sprinkled throughout. Every sentence edges toward a sermon."),

        .init(id: "peasant_en", emoji: "🧅", label: "Peasant",
              prompt: "PEASANT: Barely literate thick English dialect. Confused by anything beyond farming. Simple, earnest, frequently mentions turnips or pigs."),

        .init(id: "peasant_de", emoji: "🧅", label: "Bauer",
              prompt: "BAUER: Same barely literate peasant in thick German dialect. Bewildered, simple, probably thinking about the harvest."),

        .init(id: "nobleman_en", emoji: "🏰", label: "Scheming Nobleman",
              prompt: "SCHEMING_NOBLEMAN: Silky passive-aggressive English. Every sentence hides a veiled threat behind false courtesy. Smiles while plotting."),

        .init(id: "nobleman_de", emoji: "🏰", label: "Schleimiger Adliger",
              prompt: "SCHLEIMIGER_ADLIGER: Same scheming nobleman in archaic German. Unctuous, menacing beneath the politeness."),
    ]

    static let defaultIDs: Set<String> = ["shakespearean", "jester", "royal"]
}
