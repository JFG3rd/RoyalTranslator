import SwiftUI

struct ArchivesView: View {
    @EnvironmentObject var service: TranslatorService
    @EnvironmentObject var court: CourtViewModel
    let theme: AppTheme

    @State private var searchText = ""
    @State private var expandedIDs: Set<UUID> = []
    @Binding var selectedTab: Int

    var filteredHistory: [TranslationEntry] {
        guard !searchText.isEmpty else { return service.history }
        return service.history.filter {
            $0.original.localizedCaseInsensitiveContains(searchText)
        }
    }

    var groupedHistory: [(String, [TranslationEntry])] {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        var groups: [(String, [TranslationEntry])] = []
        var currentLabel = ""
        var currentGroup: [TranslationEntry] = []

        for entry in filteredHistory {
            let label: String
            if cal.isDateInToday(entry.date) {
                label = String(localized: "archives_today")
            } else if cal.isDateInYesterday(entry.date) {
                label = String(localized: "archives_yesterday")
            } else {
                label = formatter.string(from: entry.date)
            }
            if label != currentLabel {
                if !currentGroup.isEmpty { groups.append((currentLabel, currentGroup)) }
                currentLabel = label
                currentGroup = [entry]
            } else {
                currentGroup.append(entry)
            }
        }
        if !currentGroup.isEmpty { groups.append((currentLabel, currentGroup)) }
        return groups
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [theme.bg1, theme.bg2],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            if service.history.isEmpty {
                emptyState
            } else {
                archivesList
            }
        }
        .navigationTitle(Text("archives_title"))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: Text("archives_search"))
        .font(.custom("Georgia", size: theme.scaled(14)))
        .foregroundColor(theme.inkDark)
    }

    // MARK: - List

    var archivesList: some View {
        List {
            ForEach(groupedHistory, id: \.0) { label, entries in
                Section {
                    ForEach(entries) { entry in
                        archiveRow(entry)
                            .listRowBackground(theme.cardFill.opacity(0.7))
                            .listRowSeparatorTint(theme.faded.opacity(0.2))
                    }
                } header: {
                    Text(label)
                        .font(.custom("Georgia", size: theme.scaled(11)))
                        .kerning(1.2).textCase(.uppercase)
                        .foregroundColor(theme.faded)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Archive row

    func archiveRow(_ entry: TranslationEntry) -> some View {
        let expanded = expandedIDs.contains(entry.id)
        let hasFav = entry.styles.contains {
            service.favoritedIDs.contains("\(entry.id.uuidString):\($0.id)")
        }

        return VStack(alignment: .leading, spacing: 0) {
            // Collapsed header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expanded { expandedIDs.remove(entry.id) }
                    else        { expandedIDs.insert(entry.id) }
                }
            }) {
                HStack(spacing: 8) {
                    Text("\"\(entry.original)\"")
                        .font(.custom("Georgia", size: theme.scaled(13))).italic()
                        .foregroundColor(theme.faded)
                        .lineLimit(expanded ? nil : 1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 2) {
                        ForEach(entry.styles.prefix(4)) { s in
                            Text(s.emoji).font(.system(size: 13))
                        }
                        if entry.styles.count > 4 {
                            Text("+\(entry.styles.count - 4)")
                                .font(.custom("Georgia", size: 10))
                                .foregroundColor(theme.faded)
                        }
                    }

                    if hasFav {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11))
                            .foregroundColor(theme.accent)
                    }

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: theme.scaled(11)))
                        .foregroundColor(theme.faded)
                }
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            // Expanded bubbles
            if expanded {
                VStack(spacing: 10) {
                    ForEach(entry.styles) { style in
                        HStack(alignment: .top, spacing: 8) {
                            Text(style.emoji).font(.system(size: 18)).padding(.top, 2)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(style.label.uppercased())
                                    .font(.custom("Georgia", size: theme.scaled(9)))
                                    .kerning(1.3).foregroundColor(theme.faded)
                                Text(entry.results[style.id] ?? "—")
                                    .font(.custom("Georgia", size: theme.scaled(13))).italic()
                                    .foregroundColor(theme.inkDark)
                            }
                            Spacer()
                            Button(action: {
                                UIPasteboard.general.string = entry.results[style.id]
                            }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: theme.scaled(12)))
                                    .foregroundColor(theme.faded.opacity(0.6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.bottom, 10)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                // Navigate to Dispatch with text pre-filled
                // We post a notification that DispatchView listens to
                NotificationCenter.default.post(
                    name: .redispatch,
                    object: entry.original
                )
                selectedTab = 0
            } label: {
                Label("archives_redispatch", systemImage: "paperplane.fill")
            }
            .tint(theme.accent)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                withAnimation {
                    service.history.removeAll { $0.id == entry.id }
                    service.saveHistoryPublic()
                }
            } label: {
                Label("archives_delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Empty state

    var emptyState: some View {
        VStack(spacing: 16) {
            Text("📜").font(.system(size: 48))
            Text("archives_empty")
                .font(.custom("Georgia", size: theme.scaled(15))).italic()
                .foregroundColor(theme.faded)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
}

extension Notification.Name {
    static let redispatch = Notification.Name("com.royaltranslator.redispatch")
}
