import Foundation

/// UserDefaults keys shared by every view that reads/writes which fields
/// are shown for the "at work" status, so toggling one in Settings is
/// reflected everywhere immediately via @AppStorage.
enum DisplayPreferenceKey {
    static let showArrivalTime = "showArrivalTime"
    static let show8hCountdown = "show8hCountdown"
    static let show830Countdown = "show830Countdown"
    static let targetDisplayMode = "targetDisplayMode"
    static let hardenTokenStorage = "hardenTokenStorage"
}

/// How the 8h/8h30 targets are rendered: a countdown ("-2h45m") or the
/// absolute clock time you can leave ("17:15"). Applies everywhere the
/// targets are shown (menu bar text and the expanded popover).
enum TargetDisplayMode: String, CaseIterable, Identifiable {
    case countdown
    case leaveTime

    var id: String { rawValue }

    var label: String {
        switch self {
        case .countdown: return "Countdown"
        case .leaveTime: return "Leave time"
        }
    }
}
