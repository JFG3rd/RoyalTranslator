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
    var fixedFraction: CGPoint? = nil   // normalized 0..1 if no anchor or extraRect
    var spotPadding: CGFloat = 10
    var customSpotSize: CGSize? = nil   // used with fixedFraction
    let titleKey: LocalizedStringKey
    let bodyKey: LocalizedStringKey
    var placement: BubblePlacement = .auto

    enum BubblePlacement {
        case auto           // bubble goes to whichever side has more room
        case aboveSpot
        case belowSpot
        case center         // no spotlight — bubble floats in the middle
    }

    // 10-step tour for the Court Dispatch UI
    static var dispatchSteps: [CoachStep] { [
        // 1 — Welcome
        CoachStep(id: 0,
                  titleKey: "coach_s1_title", bodyKey: "coach_s1_body",
                  placement: .center),

        // 2 — Conversation area: small oval in the upper middle section
        CoachStep(id: 1,
                  fixedFraction: CGPoint(x: 0.5, y: 0.36),
                  customSpotSize: CGSize(width: 200, height: 120),
                  titleKey: "coach_s2_title", bodyKey: "coach_s2_body",
                  placement: .belowSpot),

        // 3 — Court badge (bottom-left of input bar)
        CoachStep(id: 2, anchorID: "court_badge",
                  titleKey: "coach_s3_title", bodyKey: "coach_s3_body",
                  placement: .aboveSpot),

        // 4 — Text input
        CoachStep(id: 3, anchorID: "text_input",
                  titleKey: "coach_s4_title", bodyKey: "coach_s4_body",
                  placement: .aboveSpot),

        // 5 — Send button
        CoachStep(id: 4, anchorID: "send_button",
                  spotPadding: 14,
                  titleKey: "coach_s5_title", bodyKey: "coach_s5_body",
                  placement: .aboveSpot),

        // 6 — Favouriting: spotlight a heart-sized area mid-right
        CoachStep(id: 5,
                  fixedFraction: CGPoint(x: 0.78, y: 0.44),
                  customSpotSize: CGSize(width: 42, height: 42),
                  titleKey: "coach_s6_title", bodyKey: "coach_s6_body",
                  placement: .belowSpot),

        // 7 — Court tab (rect injected via extraRects from actual UITabBar frame)
        // .auto: bubble goes above if tab bar is at bottom, below if tab bar is at top
        CoachStep(id: 6, anchorID: "tab_court",
                  titleKey: "coach_s7_title", bodyKey: "coach_s7_body",
                  placement: .auto),

        // 8 — Archives tab
        CoachStep(id: 7, anchorID: "tab_archives",
                  titleKey: "coach_s8_title", bodyKey: "coach_s8_body",
                  placement: .auto),

        // 9 — Favourites tab
        CoachStep(id: 8, anchorID: "tab_favourites",
                  titleKey: "coach_s9_title", bodyKey: "coach_s9_body",
                  placement: .auto),

        // 10 — Realm tab
        CoachStep(id: 9, anchorID: "tab_realm",
                  titleKey: "coach_s10_title", bodyKey: "coach_s10_body",
                  placement: .auto),
    ]}
}

// MARK: - Overlay

struct CoachMarkOverlay: View {
    let steps: [CoachStep]
    let anchors: [String: Anchor<CGRect>]   // from child views via anchorPreference
    let extraRects: [String: CGRect]         // computed rects (e.g. tab bar positions)
    let geo: GeometryProxy
    @Binding var currentStep: Int
    let theme: AppTheme
    let onDismiss: () -> Void

    private var step: CoachStep { steps[min(currentStep, steps.count - 1)] }
    private var isLast: Bool { currentStep >= steps.count - 1 }

    private let cardH: CGFloat = 170
    private let tailH: CGFloat = 11
    private let gapToSpot: CGFloat = 12   // space between tail tip and spotlight edge

    // MARK: Spotlight rect in screen coordinates

    private func spotRect() -> CGRect? {
        // 1. Check extra rects (tab bar positions computed from geometry)
        if let id = step.anchorID, let rect = extraRects[id] {
            return rect.insetBy(dx: -step.spotPadding, dy: -step.spotPadding)
        }
        // 2. Check preference-key anchors (tagged child views)
        if let id = step.anchorID, let anchor = anchors[id] {
            return geo[anchor].insetBy(dx: -step.spotPadding, dy: -step.spotPadding)
        }
        // 3. Normalized fraction fallback
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
                    p.addRoundedRect(in: rect, cornerSize: CGSize(width: 14, height: 14))
                }
                .fill(Color.black.opacity(0.65), style: FillStyle(eoFill: true))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1.5)
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

    // MARK: Bubble + tail — always clamped on-screen

    private var bubbleStack: some View {
        let spot = spotRect()
        let maxW = min(geo.size.width - 48, 310.0)
        let margin: CGFloat = 14

        // Horizontal: center bubble over spotlight, clamped to screen edges
        let spotCX  = spot?.midX ?? geo.size.width / 2
        let bubbleLeft = clamp(spotCX - maxW / 2,
                               lo: margin,
                               hi: geo.size.width - maxW - margin)
        let tailTipX = clamp(spotCX - bubbleLeft, lo: 22, hi: maxW - 22)

        let place = resolvedPlacement(spot: spot)
        let groupH = cardH + (spot != nil ? tailH : 0)

        // Vertical: position group center, clamp so it never leaves the screen
        let rawCY: CGFloat = {
            switch place {
            case .aboveSpot:
                let top = spot?.minY ?? geo.size.height / 2
                return top - gapToSpot - groupH / 2
            case .belowSpot:
                let bot = spot?.maxY ?? geo.size.height / 2
                return bot + gapToSpot + groupH / 2
            default:
                return geo.size.height / 2
            }
        }()
        let centerY = clamp(rawCY,
                            lo: margin + groupH / 2,
                            hi: geo.size.height - margin - groupH / 2)

        return VStack(spacing: 0) {
            // Tail above card  →  bubble is BELOW the spotlight
            if place == .belowSpot, spot != nil {
                tailShape(pointingUp: true, tipX: tailTipX, width: maxW)
            }

            bubbleCard.frame(width: maxW)

            // Tail below card  →  bubble is ABOVE the spotlight
            if place == .aboveSpot, spot != nil {
                tailShape(pointingUp: false, tipX: tailTipX, width: maxW)
            }
        }
        .frame(width: maxW)
        .position(x: bubbleLeft + maxW / 2, y: centerY)
        .animation(.spring(response: 0.38, dampingFraction: 0.78), value: currentStep)
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
                            .fill(i == currentStep ? theme.accent : theme.faded.opacity(0.3))
                            .frame(width: i == currentStep ? 7 : 5,
                                   height: i == currentStep ? 7 : 5)
                            .animation(.spring(response: 0.28), value: currentStep)
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
        .shadow(color: .black.opacity(0.3), radius: 18, x: 0, y: 8)
    }

    // MARK: Tail triangle

    private func tailShape(pointingUp: Bool, tipX: CGFloat, width: CGFloat) -> some View {
        Path { p in
            let half: CGFloat = 13
            if pointingUp {
                // tip at top → bubble below spotlight
                p.move(to: CGPoint(x: tipX, y: 0))
                p.addLine(to: CGPoint(x: tipX - half, y: tailH))
                p.addLine(to: CGPoint(x: tipX + half, y: tailH))
            } else {
                // tip at bottom → bubble above spotlight
                p.move(to: CGPoint(x: tipX, y: tailH))
                p.addLine(to: CGPoint(x: tipX - half, y: 0))
                p.addLine(to: CGPoint(x: tipX + half, y: 0))
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
        else { withAnimation(.easeInOut(duration: 0.25)) { currentStep += 1 } }
    }
}
