import SwiftUI

struct FavouritesView: View {
    @EnvironmentObject var service: TranslatorService
    let theme: AppTheme

    enum GroupMode: String, CaseIterable, Identifiable {
        case byCharacter, byDate
        var id: String { rawValue }
        var labelKey: LocalizedStringKey {
            self == .byCharacter ? "favs_by_character" : "favs_by_date"
        }
    }

    @State private var groupMode: GroupMode = .byCharacter

    struct FavItem: Identifiable {
        let id: String           // composite key "entryID:styleID"
        let style: TranslationStyle
        let text: String
        let original: String
        let date: Date
    }

    var favItems: [FavItem] {
        service.favoritedIDs.compactMap { key in
            let parts = key.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2,
                  let uuid = UUID(uuidString: parts[0]),
                  let entry = service.history.first(where: { $0.id == uuid }),
                  let style = entry.styles.first(where: { $0.id == parts[1] }),
                  let text = entry.results[parts[1]]
            else { return nil }
            return FavItem(id: key, style: style, text: text,
                           original: entry.original, date: entry.date)
        }
    }

    var groupedByCharacter: [(TranslationStyle, [FavItem])] {
        var dict: [String: [FavItem]] = [:]
        for item in favItems {
            dict[item.style.id, default: []].append(item)
        }
        return dict.compactMap { styleID, items in
            guard let style = TranslationStyle.all.first(where: { $0.id == styleID })
            else { return nil }
            return (style, items.sorted { $0.date > $1.date })
        }.sorted { $0.0.label < $1.0.label }
    }

    var groupedByDate: [(String, [FavItem])] {
        let cal = Calendar.current
        let fmt = DateFormatter(); fmt.dateStyle = .medium
        var result: [(String, [FavItem])] = []
        var current: (String, [FavItem])? = nil
        for item in favItems.sorted(by: { $0.date > $1.date }) {
            let label: String
            if cal.isDateInToday(item.date) { label = String(localized: "archives_today") }
            else if cal.isDateInYesterday(item.date) { label = String(localized: "archives_yesterday") }
            else { label = fmt.string(from: item.date) }
            if current?.0 == label { current!.1.append(item) }
            else {
                if let c = current { result.append(c) }
                current = (label, [item])
            }
        }
        if let c = current { result.append(c) }
        return result
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [theme.bg1, theme.bg2],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            if favItems.isEmpty {
                emptyState
            } else {
                favList
            }
        }
        .navigationTitle(Text("favs_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Picker("", selection: $groupMode) {
                    ForEach(GroupMode.allCases) { m in
                        Text(m.labelKey).tag(m)
                    }
                }
                .pickerStyle(.menu)
                .tint(theme.accent)
            }
        }
        .font(.custom("Georgia", size: theme.scaled(14)))
        .foregroundColor(theme.inkDark)
    }

    var favList: some View {
        List {
            if groupMode == .byCharacter {
                ForEach(groupedByCharacter, id: \.0.id) { style, items in
                    Section {
                        ForEach(items) { item in favRow(item) }
                    } header: {
                        HStack(spacing: 6) {
                            Text(style.emoji).font(.system(size: 16))
                            Text(style.label.uppercased())
                                .font(.custom("Georgia", size: theme.scaled(10)))
                                .kerning(1.3)
                        }
                        .foregroundColor(theme.faded)
                    }
                }
            } else {
                ForEach(groupedByDate, id: \.0) { label, items in
                    Section {
                        ForEach(items) { item in favRow(item) }
                    } header: {
                        Text(label)
                            .font(.custom("Georgia", size: theme.scaled(10)))
                            .kerning(1.3).textCase(.uppercase)
                            .foregroundColor(theme.faded)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    func favRow(_ item: FavItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(item.style.emoji).font(.system(size: 24)).padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.text)
                    .font(.custom("Georgia", size: theme.scaled(14))).italic()
                    .foregroundColor(theme.inkDark)
                Text("\"\(item.original)\"")
                    .font(.custom("Georgia", size: theme.scaled(11))).italic()
                    .foregroundColor(theme.faded)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "heart.fill")
                .font(.system(size: theme.scaled(16)))
                .foregroundColor(theme.accent)
        }
        .padding(.vertical, 6)
        .listRowBackground(theme.cardFill.opacity(0.7))
        .listRowSeparatorTint(theme.faded.opacity(0.2))
        .swipeActions(edge: .leading) {
            Button {
                UIPasteboard.general.string = item.text
            } label: {
                Label("copy", systemImage: "doc.on.doc")
            }
            .tint(theme.faded)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                service.toggleFavorite(item.id)
            } label: {
                Label("favs_remove", systemImage: "heart.slash")
            }
            .tint(theme.accent)
        }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Text("♥").font(.system(size: 48)).foregroundColor(theme.faded.opacity(0.4))
            Text("favs_empty")
                .font(.custom("Georgia", size: theme.scaled(15))).italic()
                .foregroundColor(theme.faded)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
}
