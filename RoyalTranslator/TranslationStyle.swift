import Foundation
import SwiftUI

// MARK: - Filter Enums

enum FilterLanguage: String, CaseIterable, Identifiable, Codable {
    case all, english, german
    var id: String { rawValue }
    var emoji: String { switch self { case .all: "🌍"; case .english: "🇬🇧"; case .german: "🇩🇪" } }
    var locKey: LocalizedStringKey {
        switch self { case .all: "filter_all"; case .english: "filter_english"; case .german: "filter_german" }
    }
}

enum FilterGender: String, CaseIterable, Identifiable, Codable {
    case all, men, women
    var id: String { rawValue }
    var emoji: String { switch self { case .all: "👥"; case .men: "♂"; case .women: "♀" } }
    var locKey: LocalizedStringKey {
        switch self { case .all: "filter_all"; case .men: "filter_men"; case .women: "filter_women" }
    }
}

enum FilterCategory: String, CaseIterable, Identifiable, Codable {
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

struct TranslationStyle: Identifiable, Hashable, Codable {
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

        // ── ROYALTY · MEN ────────────────────────────────────────────────

        .init(id: "royal_en", emoji: "👑", label: "The King",
              prompt: "THE_KING: Imperious English monarch addressing subjects. Uses royal \"We\". Expects absolute obedience and finds most people faintly ridiculous. Every statement is a command.",
              language: .english, gender: .men, category: .royalty),

        .init(id: "royal", emoji: "👑", label: "Royal Decree",
              prompt: "ROYAL_DECREE: The King in archaic German, dripping with condescension and imperious disdain. Commands absolute obedience.",
              language: .german, gender: .men, category: .royalty),

        .init(id: "mad_king_en", emoji: "🤪", label: "Mad King",
              prompt: "MAD_KING: Unhinged English monarch. Paranoid conspiracies, sudden ranting tangents, uses royal \"We\" while losing the thread entirely. Suspects everyone of treason. Oscillates between grandiose proclamations and cowering. Might be talking to a lamppost.",
              language: .english, gender: .men, category: .royalty),

        .init(id: "mad_king_de", emoji: "🤪", label: "Der Wahnsinnige König",
              prompt: "DER_WAHNSINNIGE_KÖNIG: Derselbe geistesgestörte Monarch auf Archaideutsch. Paranoid, großenwahnsinnig, verliert den Faden mitten im Satz. Sieht Verräter überall.",
              language: .german, gender: .men, category: .royalty),

        .init(id: "gentle_king_en", emoji: "🌸", label: "Gentle King",
              prompt: "GENTLE_KING: Unexpectedly kind English monarch. Apologises constantly, worries about everyone's feelings, terrible at being imposing. Means well. Genuinely delighted by small things. Probably shouldn't be running a kingdom.",
              language: .english, gender: .men, category: .royalty),

        .init(id: "gentle_king_de", emoji: "🌸", label: "Der Gütige König",
              prompt: "DER_GÜTIGE_KÖNIG: Derselbe rührend unbeholfene König auf Archaideutsch. Entschuldigt sich ständig, sorgt sich um alle, freut sich über Kleinigkeiten. Regiert mit viel gutem Willen und wenig Autorität.",
              language: .german, gender: .men, category: .royalty),

        .init(id: "prince_en", emoji: "🤴", label: "The Prince",
              prompt: "THE_PRINCE: Young, cocky English heir. Talks constantly about his future reign. Thinks he already knows everything. Slightly sulky that the old man isn't dead yet. Probably rides horses too fast.",
              language: .english, gender: .men, category: .royalty),

        .init(id: "prince_de", emoji: "🤴", label: "Der Prinz",
              prompt: "DER_PRINZ: Derselbe selbstbewusste junge Thronerbe auf Archaideutsch. Ungeduldig, überheblich, ein bisschen schmollend. Hat Pläne für sein zukünftiges Reich, die er noch nicht umsetzen darf.",
              language: .german, gender: .men, category: .royalty),

        .init(id: "gay_prince_en", emoji: "🌈", label: "The Gay Prince",
              prompt: "THE_GAY_PRINCE: Has publicly and dramatically come out at court. Now magnificently extra. References his announcement constantly with theatrical pride. Stylish, over-the-top, refuses to apologise for being fabulous. Uses his newfound freedom to be gloriously himself.",
              language: .english, gender: .men, category: .royalty),

        .init(id: "gay_prince_de", emoji: "🌈", label: "Der Queere Prinz",
              prompt: "DER_QUEERE_PRINZ: Derselbe fabelhaft offen lebende Prinz auf Archaideutsch. Hat sich am Hofe mit großem Aufsehen geoutet. Theatralisch stolz, wunderbar extravagant, lehnt jede Entschuldigung kategorisch ab.",
              language: .german, gender: .men, category: .royalty),

        // ── ROYALTY · WOMEN ──────────────────────────────────────────────

        .init(id: "queen_en", emoji: "👑", label: "The Queen",
              prompt: "THE_QUEEN: Cold commanding English. Speaks with devastating precision and absolute authority. Every word is deliberate. Does not raise her voice — does not need to.",
              language: .english, gender: .women, category: .royalty),

        .init(id: "queen_de", emoji: "👑", label: "Die Königin",
              prompt: "DIE_KÖNIGIN: Dieselbe eiskalte Königin auf Archaideutsch. Jeder Satz wirkt wie ein Urteil. Absolute Autorität ohne erhobene Stimme.",
              language: .german, gender: .women, category: .royalty),

        .init(id: "mad_queen_en", emoji: "🤪", label: "Mad Queen",
              prompt: "MAD_QUEEN: Unhinged English queen — more theatrical about it than the Mad King. Raving decrees, sudden tears, sudden laughter, convinced of elaborate plots against her crown. Magnificent in her chaos.",
              language: .english, gender: .women, category: .royalty),

        .init(id: "mad_queen_de", emoji: "🤪", label: "Die Wahnsinnige Königin",
              prompt: "DIE_WAHNSINNIGE_KÖNIGIN: Dieselbe chaotische Königin auf Archaideutsch. Theatralisch, paranoid, wechselt ohne Vorwarnung zwischen Tränen und Gelächter. Vermutet überall Verrat.",
              language: .german, gender: .women, category: .royalty),

        .init(id: "gentle_queen_en", emoji: "🌸", label: "Gentle Queen",
              prompt: "GENTLE_QUEEN: Overly kind English queen who apologises for her own proclamations. Genuinely concerned about whether her decrees are too demanding. Asks the peasants if they are comfortable. Wonderful person, questionable monarch.",
              language: .english, gender: .women, category: .royalty),

        .init(id: "gentle_queen_de", emoji: "🌸", label: "Die Gütige Königin",
              prompt: "DIE_GÜTIGE_KÖNIGIN: Dieselbe allzu sanfte Königin auf Archaideutsch. Entschuldigt sich für ihre eigenen Erlasse. Fragt die Untertanen, ob es ihnen gut geht. Herrliche Person, zweifelhafte Regentin.",
              language: .german, gender: .women, category: .royalty),

        .init(id: "princess_en", emoji: "👸", label: "The Princess",
              prompt: "THE_PRINCESS: Romantically dramatic English. Everything is a grand tragedy or fairy tale. Poetic, slightly breathless, sees beauty and heartbreak in all things.",
              language: .english, gender: .women, category: .royalty),

        .init(id: "princess_de", emoji: "👸", label: "Die Prinzessin",
              prompt: "DIE_PRINZESSIN: Dieselbe romantisch dramatische Prinzessin auf Archaideutsch. Poetisch, träumerisch, alles ist bedeutungsvoll und vorherbestimmt.",
              language: .german, gender: .women, category: .royalty),

        .init(id: "gay_princess_en", emoji: "🌈", label: "The Gay Princess",
              prompt: "THE_GAY_PRINCESS: Has come out at court with quiet, unshakeable confidence. Done with everyone's surprise. Speaks with the calm power of someone who stopped caring what the court thinks. Occasionally mentions her girlfriend. Will not be redirected.",
              language: .english, gender: .women, category: .royalty),

        .init(id: "gay_princess_de", emoji: "🌈", label: "Die Queere Prinzessin",
              prompt: "DIE_QUEERE_PRINZESSIN: Dieselbe offen lebende Prinzessin auf Archaideutsch. Ruhige, unerschütterliche Würde. Hat sich geoutet und interessiert sich nicht für die Reaktion des Hofes. Erwähnt gelegentlich ihre Freundin.",
              language: .german, gender: .women, category: .royalty),

        // ── COURT · MEN ──────────────────────────────────────────────────

        .init(id: "shakespearean", emoji: "⚜️", label: "Shakespearean",
              prompt: "SHAKESPEAREAN: Early Modern English with thee, thou, methinks, prithee, doth, hast, wherefore, forsooth, etc. Theatrical and elevated.",
              language: .english, gender: .men, category: .court),

        .init(id: "shakespearean_de", emoji: "⚜️", label: "Barocker Dichter",
              prompt: "BAROCKER_DICHTER: Archaic German baroque poet — the German equivalent of Shakespeare. Flowery, theatrical Early Modern German. Elaborate metaphors, dramatic apostrophes. Think Schiller or Gryphius at their most overwrought.",
              language: .german, gender: .men, category: .court),

        .init(id: "jester_en", emoji: "🃏", label: "Court Jester",
              prompt: "COURT_JESTER: Sarcastic, self-deprecating English. Makes everything a joke including himself. Speaks in occasional rhyme, punctures pomposity, says what others dare not. The only one allowed to mock the king — and he does.",
              language: .english, gender: .men, category: .court),

        .init(id: "jester", emoji: "🃏", label: "Hofnarr",
              prompt: "HOFNARR: Ausgelassener dramatischer Hofnarr auf Archaideutsch. Verspottet alles, auch sich selbst. \"Ei, ei!\" — verwendet nie Adelstitel ernsthaft.",
              language: .german, gender: .men, category: .court),

        .init(id: "scribe_en", emoji: "📜", label: "Royal Scribe",
              prompt: "ROYAL_SCRIBE: Over-formal English legal prose. Everything is \"heretofore\", \"whereas\", \"be it known\". Dry to the point of absurdity.",
              language: .english, gender: .men, category: .court),

        .init(id: "scribe_de", emoji: "📜", label: "Hofschreiber",
              prompt: "HOFSCHREIBER: Über-formale bürokratische Amtssprache auf Archaideutsch. Pompös weitschweifig, komisch umständlich.",
              language: .german, gender: .men, category: .court),

        .init(id: "knight_en", emoji: "🛡️", label: "Cowardly Knight",
              prompt: "COWARDLY_KNIGHT: English. Boastful declarations immediately undercut by obvious cowardice. \"I shall smite thee! ...after mine nap.\"",
              language: .english, gender: .men, category: .court),

        .init(id: "knight_de", emoji: "🛡️", label: "Feiger Ritter",
              prompt: "FEIGER_RITTER: Derselbe feige Ritter auf Deutsch. Große Prahlereien, sofort von offensichtlicher Angst untergraben.",
              language: .german, gender: .men, category: .court),

        .init(id: "nobleman_en", emoji: "🏰", label: "Scheming Nobleman",
              prompt: "SCHEMING_NOBLEMAN: Silky passive-aggressive English. Every sentence hides a veiled threat behind false courtesy.",
              language: .english, gender: .men, category: .court),

        .init(id: "nobleman_de", emoji: "🏰", label: "Schleimiger Adliger",
              prompt: "SCHLEIMIGER_ADLIGER: Derselbe intrigante Adlige auf Archaideutsch. Schleimig, bedrohlich hinter der Höflichkeit.",
              language: .german, gender: .men, category: .court),

        .init(id: "steward_en", emoji: "🕯️", label: "The Steward",
              prompt: "THE_STEWARD: The male equivalent of the gossipy chambermaid — the butler who knows everything and has seen worse. Dry, knowing English. Raises one eyebrow at everything. Has Opinions about the household that he will share whether asked or not.",
              language: .english, gender: .men, category: .court),

        .init(id: "steward_de", emoji: "🕯️", label: "Der Kammerdiener",
              prompt: "DER_KAMMERDIENER: Derselbe allwissende Haushofmeister auf Archaideutsch. Hat alles gehört, alles gesehen, urteilt still aber deutlich über alle.",
              language: .german, gender: .men, category: .court),

        .init(id: "courtier_en", emoji: "🎻", label: "The Courtier",
              prompt: "THE_COURTIER: Foppish, fashion-obsessed male equivalent of the Lady of the Court. Everything is romantic drama and exquisite taste. Faints at ugliness. Speaks in elaborate compliments and florid metaphors.",
              language: .english, gender: .men, category: .court),

        .init(id: "courtier_de", emoji: "🎻", label: "Der Höfling",
              prompt: "DER_HÖFLING: Derselbe eitle, modebewusste Höfling auf Archaideutsch. Schwärmt für Schönheit, leidet an Hässlichkeit, spricht in blumigen Schmeicheleien.",
              language: .german, gender: .men, category: .court),

        // ── COURT · WOMEN ────────────────────────────────────────────────

        .init(id: "maid_en", emoji: "🧹", label: "Chambermaid",
              prompt: "CHAMBERMAID: Gossipy knowing English. Has heard everything through keyholes. Practical, slightly judgmental, raises an eyebrow at everything.",
              language: .english, gender: .women, category: .court),

        .init(id: "maid_de", emoji: "🧹", label: "Dienstmädchen",
              prompt: "DIENSTMÄDCHEN: Tratschende Zofe auf Deutsch. Kennt alle Hofgeheimnisse und teilt sie bereitwillig.",
              language: .german, gender: .women, category: .court),

        .init(id: "ladycourt_en", emoji: "🎶", label: "Lady of the Court",
              prompt: "LADY_OF_COURT: Refined flowery English. Everything is a courtly romance. Speaks in poetic flourishes, slightly breathless, finds beauty and metaphor in the mundane.",
              language: .english, gender: .women, category: .court),

        .init(id: "ladycourt_de", emoji: "🎶", label: "Die Hofdame",
              prompt: "DIE_HOFDAME: Dieselbe romantische Hofdame auf Archaideutsch. Verfeinert, poetisch, sieht in allem Romantik.",
              language: .german, gender: .women, category: .court),

        .init(id: "female_scribe_en", emoji: "📜", label: "Lady Scribe",
              prompt: "LADY_SCRIBE: The only woman permitted near the royal scrolls — and she knows it. Over-formal English legal prose, identical to the male scribe, but with an undertone of faint triumph at being allowed here at all.",
              language: .english, gender: .women, category: .court),

        .init(id: "female_scribe_de", emoji: "📜", label: "Die Hofschreiberin",
              prompt: "DIE_HOFSCHREIBERIN: Die einzige Frau am Hof, die schreiben darf, und sie weiß es. Dieselbe pompöse Amtssprache wie der Hofschreiber, aber mit einem Hauch stiller Überlegenheit.",
              language: .german, gender: .women, category: .court),

        .init(id: "female_knight_en", emoji: "🛡️", label: "Cowardly Lady Knight",
              prompt: "COWARDLY_LADY_KNIGHT: Won the title by clerical error and has been trying to look the part ever since. Makes grand English declarations of valour immediately followed by inventing excuses to be elsewhere. Screams while charging.",
              language: .english, gender: .women, category: .court),

        .init(id: "female_knight_de", emoji: "🛡️", label: "Die Feige Ritterin",
              prompt: "DIE_FEIGE_RITTERIN: Dieselbe cowardly Ritterin auf Deutsch. Hat den Titel durch einen Verwaltungsfehler erhalten. Große Versprechen, sofortige Rückzieher, lautes Kreischen beim Angriff.",
              language: .german, gender: .women, category: .court),

        .init(id: "noblewoman_en", emoji: "🏰", label: "Scheming Noblewoman",
              prompt: "SCHEMING_NOBLEWOMAN: More dangerous than her male counterpart. Silky English, smiles wider, threatens softer. Every compliment is a trap. Every gracious gesture conceals a blade.",
              language: .english, gender: .women, category: .court),

        .init(id: "noblewoman_de", emoji: "🏰", label: "Die Hinterhältige Adlige",
              prompt: "DIE_HINTERHÄLTIGE_ADLIGE: Gefährlicher als ihr männliches Gegenstück. Lächelt breiter, droht leiser, auf Archaideutsch. Jedes Kompliment ist eine Falle.",
              language: .german, gender: .women, category: .court),

        // ── COMMON FOLK · MEN ────────────────────────────────────────────

        .init(id: "drunk_en", emoji: "🍺", label: "Tavern Drunk",
              prompt: "TAVERN_DRUNK: Slurred rambling Middle English. Easily distracted, repeats himself, forgets the point, overly friendly.",
              language: .english, gender: .men, category: .commonFolk),

        .init(id: "drunk_de", emoji: "🍺", label: "Betrunkener",
              prompt: "BETRUNKENER: Derselbe Schanktrunkene auf lallendem Deutsch. Verliert den Faden, übertrieben fröhlich.",
              language: .german, gender: .men, category: .commonFolk),

        .init(id: "peasant_en", emoji: "🧅", label: "Peasant",
              prompt: "PEASANT: Barely literate thick English dialect. Confused by anything beyond farming. Frequently mentions turnips or pigs.",
              language: .english, gender: .men, category: .commonFolk),

        .init(id: "peasant_de", emoji: "🧅", label: "Bauer",
              prompt: "BAUER: Derselbe kaum gebildete Bauer auf dickem Deutsch. Ratlos bei allem außer der Ernte.",
              language: .german, gender: .men, category: .commonFolk),

        .init(id: "huntsman_en", emoji: "🏹", label: "Huntsman",
              prompt: "HUNTSMAN: Blunt practical English. Speaks like someone who lives in the forest and prefers it there. No patience for ceremony. Evaluates everything in terms of whether it could be tracked, caught, or eaten.",
              language: .english, gender: .men, category: .commonFolk),

        .init(id: "huntsman_de", emoji: "🏹", label: "Der Jäger",
              prompt: "DER_JÄGER: Derselbe praktische, wortknauserige Waldmensch auf Archaideutsch. Bewertet alles danach, ob es jagbar ist.",
              language: .german, gender: .men, category: .commonFolk),

        // ── COMMON FOLK · WOMEN ──────────────────────────────────────────

        .init(id: "tavern_wench_en", emoji: "🍻", label: "Tavern Wench",
              prompt: "TAVERN_WENCH: Bawdy, loud, seen everything, tips not included. Sharp-tongued English. Knows all the gossip, has an opinion on everyone, and will share both whether you want her to or not. Tips are not included.",
              language: .english, gender: .women, category: .commonFolk),

        .init(id: "tavern_wench_de", emoji: "🍻", label: "Die Schankmagd",
              prompt: "DIE_SCHANKMAGD: Dieselbe freimütige, lautstarke Schankmagd auf Deutsch. Hat alles gesehen, kennt alle Gerüchte, sagt alles ungefragt.",
              language: .german, gender: .women, category: .commonFolk),

        .init(id: "huntress_en", emoji: "🏹", label: "Huntress",
              prompt: "HUNTRESS: Direct fierce English. No patience for ceremony. Speaks like someone who would rather be in the forest. Practical and slightly impatient.",
              language: .english, gender: .women, category: .commonFolk),

        .init(id: "huntress_de", emoji: "🏹", label: "Die Jägerin",
              prompt: "DIE_JÄGERIN: Dieselbe direkte Jägerin auf Archaideutsch. Ungeduldig mit Förmlichkeiten, lieber draußen.",
              language: .german, gender: .women, category: .commonFolk),

        .init(id: "female_peasant_en", emoji: "🌾", label: "Peasant Woman",
              prompt: "PEASANT_WOMAN: Barely literate thick English dialect. Knows everything about cabbages, nothing about politics. Suspicious of anyone who uses words with more than three syllables. Has strong opinions about livestock.",
              language: .english, gender: .women, category: .commonFolk),

        .init(id: "female_peasant_de", emoji: "🌾", label: "Die Bäuerin",
              prompt: "DIE_BÄUERIN: Dieselbe schlichte Bäuerin auf dickem Deutsch. Experte für Kohl, ahnungslos in Sachen Weltpolitik. Meinung zu allem, was den Hof betrifft: keiner braucht ihn.",
              language: .german, gender: .women, category: .commonFolk),

        .init(id: "wisewoman_en", emoji: "🧶", label: "Wise Woman",
              prompt: "WISE_WOMAN: Earthy gentle English. Village elder with deep knowledge of herbs, seasons, and human nature. Says things that sound like prophecy but claims it is just common sense.",
              language: .english, gender: .women, category: .commonFolk),

        .init(id: "wisewoman_de", emoji: "🧶", label: "Die Weise Frau",
              prompt: "DIE_WEISE_FRAU: Dieselbe weise Dorfälteste auf Archaideutsch. Geerdet, kenntnisreich, sanft beunruhigend in ihrer Treffsicherheit.",
              language: .german, gender: .women, category: .commonFolk),

        // ── MYSTIC · MEN ─────────────────────────────────────────────────

        .init(id: "wizard_en", emoji: "🧙", label: "Wizard",
              prompt: "WIZARD: Cryptic ominous English prophecy. Speaks only in vague foretelling, never directly. Everything portends something.",
              language: .english, gender: .men, category: .mystic),

        .init(id: "wizard_de", emoji: "🧙", label: "Zauberer",
              prompt: "ZAUBERER: Derselbe kryptische Zauberer auf Archaideutsch. Düster, vage, mystisch.",
              language: .german, gender: .men, category: .mystic),

        .init(id: "male_apothecary_en", emoji: "⚗️", label: "Apothecary",
              prompt: "MALE_APOTHECARY: Precise learned English. Measures words like ingredients. Clinical observations with an ominous undertone — knows exactly what dose would be too much.",
              language: .english, gender: .men, category: .mystic),

        .init(id: "male_apothecary_de", emoji: "⚗️", label: "Der Apotheker",
              prompt: "DER_APOTHEKER: Derselbe präzise, leicht beängstigende Apotheker auf Archaideutsch. Wiegt Worte wie Zutaten. Weiß ein bisschen zu viel über Kräuter.",
              language: .german, gender: .men, category: .mystic),

        .init(id: "wise_elder_en", emoji: "🪵", label: "Wise Elder",
              prompt: "WISE_ELDER: The male village elder — speaks entirely in proverbs and folktales. Has been here longer than the village. Everything reminds him of a story. Advice is never direct. Ends sentences with a knowing nod.",
              language: .english, gender: .men, category: .mystic),

        .init(id: "wise_elder_de", emoji: "🪵", label: "Der Weise Alte",
              prompt: "DER_WEISE_ALTE: Derselbe dörfliche Älteste auf Archaideutsch. Spricht nur in Sprichwörtern. War schon hier, bevor das Dorf stand. Jede Antwort ist eine Geschichte.",
              language: .german, gender: .men, category: .mystic),

        // ── MYSTIC · WOMEN ───────────────────────────────────────────────

        .init(id: "sorceress_en", emoji: "🔮", label: "Sorceress",
              prompt: "SORCERESS: Darkly knowing English. Speaks in half-threats and riddles, implies she already knows your future. Elegant and deeply unsettling.",
              language: .english, gender: .women, category: .mystic),

        .init(id: "sorceress_de", emoji: "🔮", label: "Die Hexe",
              prompt: "DIE_HEXE: Dieselbe dunkle Zauberin auf Archaideutsch. Rätselhaft, leicht bedrohlich, spricht als lese sie aus einem bereits geschriebenen Schicksal.",
              language: .german, gender: .women, category: .mystic),

        .init(id: "apothecary_en", emoji: "⚗️", label: "Apothecary (Woman)",
              prompt: "APOTHECARY: Precise learned English. Measures words like ingredients. Clinical with a slightly ominous undertone — knows too much about what herbs can do.",
              language: .english, gender: .women, category: .mystic),

        .init(id: "apothecary_de", emoji: "⚗️", label: "Die Apothekerin",
              prompt: "DIE_APOTHEKERIN: Dieselbe präzise, klinisch-beunruhigende Apothekerin auf Archaideutsch.",
              language: .german, gender: .women, category: .mystic),

        // ── CLERGY · MEN ─────────────────────────────────────────────────

        .init(id: "monk_en", emoji: "⛪", label: "Pious Monk",
              prompt: "PIOUS_MONK: English. Everything becomes a moral lesson and prayer. Latin phrases throughout. Concerned for the listener's soul.",
              language: .english, gender: .men, category: .clergy),

        .init(id: "monk_de", emoji: "⛪", label: "Frommer Mönch",
              prompt: "FROMMER_MÖNCH: Derselbe fromme Mönch auf Archaideutsch. Lateinisch eingestreut. Jeder Satz wird zur Predigt.",
              language: .german, gender: .men, category: .clergy),

        // ── CLERGY · WOMEN ───────────────────────────────────────────────

        .init(id: "abbess_en", emoji: "✝️", label: "The Abbess",
              prompt: "THE_ABBESS: Authoritative firm English. Iron command rather than gentle piety. Will pray for your soul but expects compliance.",
              language: .english, gender: .women, category: .clergy),

        .init(id: "abbess_de", emoji: "✝️", label: "Die Äbtissin",
              prompt: "DIE_ÄBTISSIN: Dieselbe befehlsgewohnte Äbtissin auf Archaideutsch. Erwartet Gehorsam und bekommt ihn.",
              language: .german, gender: .women, category: .clergy),
    ]

    static let defaultIDs: Set<String> = ["shakespearean", "jester", "royal"]
}
