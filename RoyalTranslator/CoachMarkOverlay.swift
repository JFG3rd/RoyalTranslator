import SwiftUI

// MARK: - Preference key — collects view bounds by string ID

struct CoachAnchorKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    func coachMarkAnchor(_ id: String) -> some View {
        anchorPreference(key: CoachAnchorKey.self, value: .bounds) { [id: $0] }
    }
}

// MARK: - Step definition

struct CoachStep: Identifiable {
    let id: Int
    var anchorID: String? = nil
    var fixedFraction: CGPoint? = nil   // normalized 0..1 if no anchor
    var spotPadding: CGFloat = 10
    var customSpotSize: CGSize? = nil   // used with fixedFraction
    let titleKey: LocalizedStringKey
    let bodyKey: LocalizedStringKey
    var placement: BubblePlacement = .auto

    enum BubblePlacement {
        case auto       // bubble goes to whichever side has more room
        case aboveSpot
        case belowSpot
        case center     // no spotlight — bubble floats in middle
    }

    // Steps for the Court Dispatch UI
    static var dispatchSteps: [CoachStep] { [
        // 1 — Welcome: no spotlight, centered
        CoachStep(id: 0,
                  titleKey: "coach_s1_title", bodyKey: "coach_s1_body",
                  placement: .center),

        // 2 — Conversation area: small indicator in middle of screen
        //     (using fixedFraction so we don't spotlight the whole scroll view)
        CoachStep(id: 1,
                  fixedFraction: CGPoint(x: 0.5, y: 0.38),
                  customSpotSize: CGSize(width: 180, height: 130),
                  titleKey: "coach_s2_title", bodyKey: "coach_s2_body",
                  placement: .belowSpot),

        // 3 — Court badge (bottom-left input bar): bubble above
        CoachStep(id: 2, anchorID: "court_badge",
                  titleKey: "coach_s3_title", bodyKey: "coach_s3_body",
                  placement: .aboveSpot),

        // 4 — Text input: bubble above
        CoachStep(id: 3, anchorID: "text_input",
                  titleKey: "coach_s4_title", bodyKey: "coach_s4_body",
                  placement: .aboveSpot),

        // 5 — Send button: bubble above
        CoachStep(id: 4, anchorID: "send_button",
                  spotPadding: 14,
                  titleKey: "coach_s5_title", bodyKey: "coach_s5_body",
                  placement: .aboveSpot),

        // 6 — Favouriting: fixed position near middle, bubble below
        CoachStep(id: 5,
                  fixedFraction: CGPoint(x: 0.75, y: 0.42),
                  customSpotSize: CGSize(width: 44, height: 44),
                  titleKey: "coach_s6_title", bodyKey: "coach_s6_body",
                  placement: .belowSpot),

        // 7 — Archives tab: fixed at tab bar
        CoachStep(id: 6,
                  fixedFraction: CGPoint(x: 0.5, y: 0.935),
                  customSpotSize: CGSize(width: 62, height: 54),
                  titleKey: "coach_s7_title", bodyKey: "coach_s7_body",
                  placement: .aboveSpot),

        // 8 — Realm tab: fixed at tab bar
        CoachStep(id: 7,
                  fixedFraction: CGPoint(x: 0.9, y: 0.935),
                  customSpotSize: CGSize(width: 62, height: 54),
                  titleKey: "coach_s8_title", bodyKey: "coach_s8_body",
                  placement: .aboveSpot),
    ]}
}

// MARK: - Overlay

struct CoachMarkOverlay: View {
    let steps: [CoachStep]
    let anchors: [String: Anchor<CGRect>]
    let geo: GeometryProxy
    @Binding var currentStep: Int
    let theme: AppTheme
    let onDismiss: () -> Void

    private var step: CoachStep { steps[min(currentStep, steps.count - 1)] }
    private var isLast: Bool { currentStep >= steps.count - 1 }

    // Estimated bubble card height (title + body + progress row + padding)
    private let cardH: CGFloat = 170
    private let tailH: CGFloat = 11

    // MARK: Computed spot rect (screen coordinates)

    private func spotRect() -> CGRect? {
        if let id = step.anchorID, let anchor = anchors[id] {
            return geo[anchor].insetBy(dx: -step.spotPadding, dy: -step.spotPadding)
        }
        if let frac = step.fixedFraction {
            let sz = step.customSpotSize ?? CGSize(width: 54, height: 54)
            return CGRect(
                x: geo.size.width  * frac.x - sz.width  / 2,
                y: geo.size.height * frac.y - sz.height / 2,
                width: sz.width, height: sz.height)
        }
        return nil
    }

    // MARK: Body

    var body: some View {
        ZStack {
            dimming
            bubbleStack
        }
        .transition(.opacity)
    }

    // MARK: Dimming + spotlight hole

    private var dimming: some View {
        Group {
            if let rect = spotRect() {
                Path { p in
                    p.addRect(CGRect(origin: .zero, size: geo.size))
                    p.addRoundedRect(in: rect, cornerSize: CGSize(width: 16, height: 16))
                }
                .fill(Color.black.opacity(0.65), style: FillStyle(eoFill: true))
                .overlay {
                    // Subtle white glow ring around the spotlight
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1.5)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                }
            } else {
                Color.black.opacity(0.65)
            }
        }
        .ignoresSafeArea()
        .onTapGesture { advance() }
    }

    // MARK: Bubble + tail, always clamped on-screen

    private var bubbleStack: some View {
        let spot = spotRect()
        let maxW = min(geo.size.width - 48, 320.0)
        let margin: CGFloat = 16

        // Horizontal: center bubble over spotlight, clamped to screen edges
        let spotCX = spot?.midX ?? geo.size.width / 2
        let bubbleLeft = clamp(spotCX - maxW / 2,
                               lo: margin,
                               hi: geo.size.width - maxW - margin)
        // Tail tip X within the bubble width
        let tailTipX = clamp(spotCX - bubbleLeft, lo: 22, hi: maxW - 22)

        // Determine placement
        let place = resolvedPlacement(spot: spot)

        // Vertical: position the card center, then clamp so it stays on screen
        let groupH = cardH + (spot != nil ? tailH : 0)
        let rawCenterY: CGFloat = {
            switch place {
            case .aboveSpot:
                let spotTop = spot?.minY ?? geo.size.height / 2
                return spotTop - 20 - groupH / 2
            case .belowSpot:
                let spotBottom = spot?.maxY ?? geo.size.height / 2
                return spotBottom + 20 + groupH / 2
            case .center, .auto:
                return geo.size.height / 2
            }
        }()
        let centerY = clamp(rawCenterY,
                            lo: margin + groupH / 2,
                            hi: geo.size.height - margin - groupH / 2)

        return VStack(spacing: 0) {
            // Tail on top → bubble is below spotlight
            if place == .belowSpot, spot != nil {
                tailTriangle(pointingUp: true, tipX: tailTipX, width: maxW)
            }

            bubbleCard
                .frame(width: maxW)

            // Tail on bottom → bubble is above spotlight
            if place == .aboveSpot, spot != nil {
                tailTriangle(pointingUp: false, tipX: tailTipX, width: maxW)
            }
        }
        .frame(width: maxW)
        .position(x: bubbleLeft + maxW / 2, y: centerY)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentStep)
    }

    // MARK: Bubble card

    private var bubbleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(step.titleKey)
                .font(.custom("Georgia", size: theme.scaled(16))).bold()
                .foregroundColor(theme.accent)

            Text(step.bodyKey)
                .font(.custom("Georgia", size: theme.scaled(14))).italic()
                .foregroundColor(theme.inkDark)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .center, spacing: 0) {
                // Progress dots
                HStack(spacing: 5) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Circle()
                            .fill(i == currentStep ? theme.accent : theme.faded.opacity(0.35))
                            .frame(width: i == currentStep ? 7 : 5,
                                   height: i == currentStep ? 7 : 5)
                            .animation(.spring(response: 0.3, dampingFraction: 0.65),
                                       value: currentStep)
                    }
                }
                Spacer()
                Button(action: onDismiss) {
                    Text("coach_skip")
                        .font(.custom("Georgia", size: theme.scaled(12)))
                        .foregroundColor(theme.faded)
                }
                .padding(.trailing, 10)
                Button(action: advance) {
                    Text(isLast ? "coach_done" : "coach_next")
                        .font(.custom("Georgia", size: theme.scaled(13))).fontWeight(.semibold)
                        .padding(.horizontal, 18).padding(.vertical, 8)
                        .background(theme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(22)
                }
            }
        }
        .padding(18)
        .background(theme.cardFill)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)
    }

    // MARK: Tail triangle

    private func tailTriangle(pointingUp: Bool, tipX: CGFloat, width: CGFloat) -> some View {
        Path { p in
            let halfBase: CGFloat = 13
            if pointingUp {
                p.move(to: CGPoint(x: tipX, y: 0))
                p.addLine(to: CGPoint(x: tipX - halfBase, y: tailH))
                p.addLine(to: CGPoint(x: tipX + halfBase, y: tailH))
            } else {
                p.move(to: CGPoint(x: tipX, y: tailH))
                p.addLine(to: CGPoint(x: tipX - halfBase, y: 0))
                p.addLine(to: CGPoint(x: tipX + halfBase, y: 0))
            }
            p.closeSubpath()
        }
        .fill(theme.cardFill)
        .frame(width: width, height: tailH)
    }

    // MARK: Helpers

    private func resolvedPlacement(spot: CGRect?) -> CoachStep.BubblePlacement {
        switch step.placement {
        case .aboveSpot: return .aboveSpot
        case .belowSpot: return .belowSpot
        case .center:    return .center
        case .auto:
            guard let rect = spot else { return .center }
            return rect.midY > geo.size.height * 0.5 ? .aboveSpot : .belowSpot
        }
    }

    private func clamp(_ v: CGFloat, lo: CGFloat, hi: CGFloat) -> CGFloat {
        max(lo, min(hi, v))
    }

    private func advance() {
        if isLast { onDismiss() }
        else { withAnimation(.easeInOut(duration: 0.28)) { currentStep += 1 } }
    }
}
