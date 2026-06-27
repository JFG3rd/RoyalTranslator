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
        case center     // no spotlight — bubble floats in the middle
    }

    // Steps for the Court Dispatch UI
    static var dispatchSteps: [CoachStep] { [
        CoachStep(id: 0,
                  titleKey: "coach_s1_title", bodyKey: "coach_s1_body",
                  placement: .center),

        CoachStep(id: 1, anchorID: "conversation",
                  titleKey: "coach_s2_title", bodyKey: "coach_s2_body",
                  placement: .belowSpot),

        CoachStep(id: 2, anchorID: "court_badge",
                  titleKey: "coach_s3_title", bodyKey: "coach_s3_body"),

        CoachStep(id: 3, anchorID: "text_input",
                  titleKey: "coach_s4_title", bodyKey: "coach_s4_body"),

        CoachStep(id: 4, anchorID: "send_button",
                  spotPadding: 14,
                  titleKey: "coach_s5_title", bodyKey: "coach_s5_body"),

        CoachStep(id: 5, anchorID: "conversation",
                  titleKey: "coach_s6_title", bodyKey: "coach_s6_body",
                  placement: .belowSpot),

        CoachStep(id: 6,
                  fixedFraction: CGPoint(x: 0.5, y: 0.935),
                  customSpotSize: CGSize(width: 62, height: 58),
                  titleKey: "coach_s7_title", bodyKey: "coach_s7_body",
                  placement: .aboveSpot),

        CoachStep(id: 7,
                  fixedFraction: CGPoint(x: 0.9, y: 0.935),
                  customSpotSize: CGSize(width: 62, height: 58),
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

    // MARK: Computed spot rect

    private func spotRect() -> CGRect? {
        if let id = step.anchorID, let anchor = anchors[id] {
            return geo[anchor].insetBy(dx: -step.spotPadding, dy: -step.spotPadding)
        }
        if let frac = step.fixedFraction {
            let sz = step.customSpotSize ?? CGSize(width: 54, height: 54)
            return CGRect(
                x: geo.size.width * frac.x - sz.width / 2,
                y: geo.size.height * frac.y - sz.height / 2,
                width: sz.width, height: sz.height)
        }
        return nil
    }

    // MARK: Body

    var body: some View {
        ZStack {
            dimming
            bubble
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }

    // MARK: Dimming + spotlight hole

    private var dimming: some View {
        Group {
            if let rect = spotRect() {
                // Even-odd path creates a transparent "hole" over the target view
                Path { p in
                    p.addRect(CGRect(origin: .zero, size: geo.size))
                    p.addRoundedRect(in: rect,
                                     cornerSize: CGSize(width: 16, height: 16))
                }
                .fill(Color.black.opacity(0.65), style: FillStyle(eoFill: true))
                // Subtle glow ring around spotlight
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1.5)
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

    // MARK: Bubble + tail

    private var bubble: some View {
        let spot = spotRect()
        let maxW = min(geo.size.width - 48, 320.0)

        // Horizontal: center bubble over spotlight (or screen center), clamped to edges
        let spotCX = spot?.midX ?? geo.size.width / 2
        let bubbleLeft = clamped(spotCX - maxW / 2, lo: 20, hi: geo.size.width - maxW - 20)
        // Tail tip X relative to bubble's left edge (clamped within bubble)
        let tailTip = clamped(spotCX - bubbleLeft, lo: 22, hi: maxW - 22)

        let placement = resolvedPlacement(spot: spot)
        let estimatedCardH: CGFloat = 160
        let tailH: CGFloat = 11

        // Vertical center of the whole (card + tail) group
        let groupCenterY: CGFloat = {
            switch placement {
            case .aboveSpot:
                let spotTop = spot?.minY ?? geo.size.height / 2
                // group bottom = spotTop - gap, group center = bottom - groupH/2
                let groupH = estimatedCardH + tailH
                return (spotTop - 18) - groupH / 2
            case .belowSpot:
                let spotBottom = spot?.maxY ?? geo.size.height / 2
                let groupH = estimatedCardH + tailH
                return (spotBottom + 18) + groupH / 2
            case .center:
                return geo.size.height / 2
            case .auto:
                return geo.size.height / 2  // shouldn't reach here after resolvedPlacement
            }
        }()

        return VStack(spacing: 0) {
            // Tail above card (bubble is below spotlight)
            if placement == .belowSpot {
                tailShape(pointDown: false, tipX: tailTip, totalWidth: maxW)
            }

            bubbleCard
                .frame(width: maxW)

            // Tail below card (bubble is above spotlight)
            if placement == .aboveSpot {
                tailShape(pointDown: true, tipX: tailTip, totalWidth: maxW)
            }
        }
        .frame(width: maxW)
        .position(x: bubbleLeft + maxW / 2, y: groupCenterY)
    }

    // MARK: Bubble card

    private var bubbleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(step.titleKey)
                .font(.custom("Georgia", size: theme.scaled(16))).bold()
                .foregroundColor(theme.accent)

            // Body
            Text(step.bodyKey)
                .font(.custom("Georgia", size: theme.scaled(14))).italic()
                .foregroundColor(theme.inkDark)
                .fixedSize(horizontal: false, vertical: true)

            // Progress dots + navigation
            HStack(alignment: .center, spacing: 0) {
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
        .shadow(color: .black.opacity(0.28), radius: 20, x: 0, y: 8)
    }

    // MARK: Tail triangle

    private func tailShape(pointDown: Bool, tipX: CGFloat, totalWidth: CGFloat) -> some View {
        Path { p in
            let h: CGFloat = 11
            let halfBase: CGFloat = 12
            if pointDown {
                // tip at bottom, base at top
                p.move(to: CGPoint(x: tipX, y: h))
                p.addLine(to: CGPoint(x: tipX - halfBase, y: 0))
                p.addLine(to: CGPoint(x: tipX + halfBase, y: 0))
            } else {
                // tip at top, base at bottom
                p.move(to: CGPoint(x: tipX, y: 0))
                p.addLine(to: CGPoint(x: tipX - halfBase, y: h))
                p.addLine(to: CGPoint(x: tipX + halfBase, y: h))
            }
            p.closeSubpath()
        }
        .fill(theme.cardFill)
        .frame(width: totalWidth, height: 11)
    }

    // MARK: Helpers

    private func resolvedPlacement(spot: CGRect?) -> CoachStep.BubblePlacement {
        switch step.placement {
        case .aboveSpot: return .aboveSpot
        case .belowSpot: return .belowSpot
        case .center:    return .center
        case .auto:
            guard let rect = spot else { return .center }
            // Place bubble on whichever side has more vertical room
            return rect.midY > geo.size.height * 0.5 ? .aboveSpot : .belowSpot
        }
    }

    private func clamped(_ v: CGFloat, lo: CGFloat, hi: CGFloat) -> CGFloat {
        max(lo, min(hi, v))
    }

    private func advance() {
        if isLast { onDismiss() }
        else { withAnimation(.easeInOut(duration: 0.28)) { currentStep += 1 } }
    }
}
