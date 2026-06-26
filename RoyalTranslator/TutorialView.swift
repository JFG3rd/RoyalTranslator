import SwiftUI

// MARK: - Tutorial Step

private struct TutorialStep {
    let emoji: String
    let titleKey: LocalizedStringKey
    let bodyKey: LocalizedStringKey
}

private let steps: [TutorialStep] = [
    .init(emoji: "🏰",
          titleKey: "tutorial_step1_title",
          bodyKey:  "tutorial_step1_body"),
    .init(emoji: "🎭",
          titleKey: "tutorial_step2_title",
          bodyKey:  "tutorial_step2_body"),
    .init(emoji: "🌍",
          titleKey: "tutorial_step3_title",
          bodyKey:  "tutorial_step3_body"),
    .init(emoji: "✍️",
          titleKey: "tutorial_step4_title",
          bodyKey:  "tutorial_step4_body"),
    .init(emoji: "👑",
          titleKey: "tutorial_step5_title",
          bodyKey:  "tutorial_step5_body"),
    .init(emoji: "↩️",
          titleKey: "tutorial_step6_title",
          bodyKey:  "tutorial_step6_body"),
    .init(emoji: "♥",
          titleKey: "tutorial_step7_title",
          bodyKey:  "tutorial_step7_body"),
]

// MARK: - TutorialView

struct TutorialView: View {
    @Binding var isPresented: Bool
    let theme: AppTheme

    @AppStorage("hideTutorial") var hideTutorial = false
    @State private var currentStep = 0

    var body: some View {
        ZStack {
            LinearGradient(colors: [theme.bg1, theme.bg2],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Header
                HStack {
                    Text("tutorial_title")
                        .font(.custom("Georgia", size: theme.scaled(20))).fontWeight(.bold)
                        .foregroundColor(theme.accent)
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .foregroundColor(theme.faded)
                            .font(.system(size: theme.scaled(18)))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)
                .padding(.bottom, 20)

                // Paged step cards
                TabView(selection: $currentStep) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        stepCard(step, index: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: 340)

                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Circle()
                            .fill(i == currentStep ? theme.accent : theme.faded.opacity(0.35))
                            .frame(width: i == currentStep ? 8 : 6, height: i == currentStep ? 8 : 6)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
                    }
                }
                .padding(.top, 16)

                Spacer(minLength: 20)

                // Nav buttons
                HStack(spacing: 12) {
                    if currentStep > 0 {
                        Button(action: { withAnimation { currentStep -= 1 } }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: theme.scaled(14)))
                                .foregroundColor(theme.faded)
                                .padding(.horizontal, 18).padding(.vertical, 10)
                                .background(theme.chipOff)
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6)
                                    .stroke(theme.faded.opacity(0.4), lineWidth: 1))
                        }
                    }
                    Spacer()
                    if currentStep < steps.count - 1 {
                        Button(action: { withAnimation { currentStep += 1 } }) {
                            HStack(spacing: 6) {
                                Text("tutorial_next")
                                Image(systemName: "chevron.right")
                            }
                            .font(.custom("Georgia", size: theme.scaled(15)))
                            .foregroundColor(theme.bg1)
                            .padding(.horizontal, 22).padding(.vertical, 10)
                            .background(theme.accent)
                            .cornerRadius(6)
                        }
                    } else {
                        Button(action: { isPresented = false }) {
                            Text("tutorial_done")
                                .font(.custom("Georgia", size: theme.scaled(15)))
                                .foregroundColor(theme.bg1)
                                .padding(.horizontal, 22).padding(.vertical, 10)
                                .background(theme.accent)
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(.horizontal, 28)

                // Hide toggle
                Toggle(isOn: $hideTutorial) {
                    Text("tutorial_hide")
                        .font(.custom("Georgia", size: theme.scaled(12)))
                        .foregroundColor(theme.faded)
                }
                .tint(theme.accent)
                .padding(.horizontal, 28)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
        }
        .font(.custom("Georgia", size: theme.scaled(15)))
        .foregroundColor(theme.inkDark)
    }

    private func stepCard(_ step: TutorialStep, index: Int) -> some View {
        VStack(spacing: 16) {
            Text(step.emoji)
                .font(.system(size: 48))
            Text(step.titleKey)
                .font(.custom("Georgia", size: theme.scaled(18))).fontWeight(.bold)
                .foregroundColor(theme.accent)
                .multilineTextAlignment(.center)
            Text(step.bodyKey)
                .font(.custom("Georgia", size: theme.scaled(14)))
                .foregroundColor(theme.inkDark)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(theme.cardFill)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.cardStroke, lineWidth: 1))
        .padding(.horizontal, 28)
    }
}
