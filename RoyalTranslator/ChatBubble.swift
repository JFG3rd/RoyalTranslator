import SwiftUI

// MARK: - User input bubble (right-aligned)

struct UserBubble: View {
    let text: String
    let theme: AppTheme
    var onRedispatch: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer(minLength: 48)
            VStack(alignment: .trailing, spacing: 6) {
                Text("\"\(text)\"")
                    .font(.custom("Georgia", size: theme.scaled(15))).italic()
                    .foregroundColor(theme.inkDark)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(theme.inputFill)
                    .clipShape(RoundedCorner(radius: 14, corners: [.topLeft, .bottomLeft, .bottomRight]))
                    .overlay(
                        RoundedCorner(radius: 14, corners: [.topLeft, .bottomLeft, .bottomRight])
                            .stroke(theme.cardStroke, lineWidth: 1)
                    )
                if onRedispatch != nil {
                    Button(action: { onRedispatch?() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: theme.scaled(11)))
                            .foregroundColor(theme.faded)
                    }
                }
            }
        }
    }
}

// MARK: - Character reply bubble (left-aligned)

struct CharacterBubble: View {
    let style: TranslationStyle
    let text: String
    let theme: AppTheme
    var isFavorited: Bool = false
    var onCopy: (() -> Void)? = nil
    var onToggleFavorite: (() -> Void)? = nil

    @State private var heartScale: CGFloat = 1.0
    @State private var copied = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(style.emoji)
                .font(.system(size: 24))
                .frame(width: 32)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 5) {
                // Character name label
                Text("\(style.emoji) \(style.label.uppercased())")
                    .font(.custom("Georgia", size: theme.scaled(9)))
                    .kerning(1.5)
                    .foregroundColor(theme.faded)

                // Bubble body
                VStack(alignment: .leading, spacing: 8) {
                    Text(text)
                        .font(.custom("Georgia", size: theme.scaled(15))).italic()
                        .foregroundColor(theme.inkDark)
                        .fixedSize(horizontal: false, vertical: true)

                    // Action row
                    HStack(spacing: 14) {
                        Spacer()
                        Button(action: {
                            UIPasteboard.general.string = text
                            withAnimation { copied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation { copied = false }
                            }
                            onCopy?()
                        }) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: theme.scaled(13)))
                                .foregroundColor(copied ? theme.accent : theme.faded.opacity(0.6))
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { heartScale = 1.45 }
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.55).delay(0.15)) { heartScale = 1.0 }
                            onToggleFavorite?()
                        }) {
                            Image(systemName: isFavorited ? "heart.fill" : "heart")
                                .font(.system(size: theme.scaled(16)))
                                .foregroundColor(isFavorited ? theme.accent : theme.faded.opacity(0.55))
                                .scaleEffect(heartScale)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(
                    HStack(spacing: 0) {
                        theme.accent.opacity(0.55).frame(width: 2)
                        theme.cardFill
                    }
                )
                .clipShape(RoundedCorner(radius: 14, corners: [.topRight, .bottomLeft, .bottomRight]))
                .overlay(
                    RoundedCorner(radius: 14, corners: [.topRight, .bottomLeft, .bottomRight])
                        .stroke(theme.cardStroke, lineWidth: 1)
                )
            }

            Spacer(minLength: 24)
        }
    }
}

// MARK: - Typing indicator bubble

struct TypingBubble: View {
    let activeEmojis: [String]
    let theme: AppTheme

    @State private var dotPhase = 0
    @State private var emojiIndex = 0

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(activeEmojis.isEmpty ? "⚜️" : activeEmojis[emojiIndex % activeEmojis.count])
                .font(.system(size: 24))
                .frame(width: 32)
                .padding(.top, 4)
                .animation(.easeInOut(duration: 0.4), value: emojiIndex)

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(theme.faded)
                        .frame(width: 7, height: 7)
                        .opacity(dotPhase == i ? 1.0 : 0.3)
                        .animation(.easeInOut(duration: 0.4).repeatForever(), value: dotPhase)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(theme.cardFill)
            .clipShape(RoundedCorner(radius: 14, corners: [.topRight, .bottomLeft, .bottomRight]))
            .overlay(
                RoundedCorner(radius: 14, corners: [.topRight, .bottomLeft, .bottomRight])
                    .stroke(theme.cardStroke, lineWidth: 1)
            )

            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                dotPhase = (dotPhase + 1) % 3
            }
            Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { _ in
                emojiIndex += 1
            }
        }
    }
}

// MARK: - Rounded corner shape helper

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
