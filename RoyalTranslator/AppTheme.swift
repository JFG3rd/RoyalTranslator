import SwiftUI

struct AppTheme {
    let scheme: ColorScheme
    // Default 17 = original 16 + the requested +1.
    // The slider stores the user's chosen value; scaled() shifts every
    // content font by (base - 16) so the default is already +1.
    let base: CGFloat

    init(scheme: ColorScheme, base: CGFloat = 17) {
        self.scheme = scheme
        self.base = base
    }

    var isDark: Bool { scheme == .dark }

    // MARK: - Font scaling

    /// Shift any content size by the user's preference.
    /// App titles are intentionally excluded from this helper.
    func scaled(_ size: CGFloat) -> CGFloat {
        max(8, size + (base - 16))
    }

    // MARK: - Backgrounds

    var bg1: Color { isDark
        ? Color(red: 0.08, green: 0.05, blue: 0.02)
        : Color(red: 0.96, green: 0.93, blue: 0.84) }
    var bg2: Color { isDark
        ? Color(red: 0.13, green: 0.08, blue: 0.03)
        : Color(red: 0.93, green: 0.88, blue: 0.72) }

    // Burgundy accent — brighter in dark mode
    var accent: Color { isDark
        ? Color(red: 0.75, green: 0.22, blue: 0.10)
        : Color(red: 0.48, green: 0.23, blue: 0.12) }

    // Gold — more saturated in dark mode
    var faded: Color { isDark
        ? Color(red: 0.80, green: 0.62, blue: 0.25)
        : Color(red: 0.62, green: 0.55, blue: 0.43) }

    // Text
    var inkDark: Color { isDark
        ? Color(red: 0.93, green: 0.88, blue: 0.76)
        : Color(red: 0.10, green: 0.07, blue: 0.035) }

    // Card surfaces
    var cardFill: Color   { isDark ? Color.white.opacity(0.06) : Color.white.opacity(0.40) }
    var cardStroke: Color { isDark ? Color.white.opacity(0.14) : faded }
    var inputFill: Color  { isDark ? Color.white.opacity(0.08) : Color.white.opacity(0.60) }
    var rowAlt: Color     { isDark ? Color.black.opacity(0.25) : Color.black.opacity(0.06) }

    // Chip selected
    var chipOn: Color  { accent }
    var chipOff: Color { isDark ? Color.white.opacity(0.10) : Color.white.opacity(0.35) }
    var chipOnText: Color  { isDark ? Color(red: 0.97, green: 0.93, blue: 0.82) : Color(red: 0.96, green: 0.93, blue: 0.84) }
    var chipOffText: Color { faded }
}
