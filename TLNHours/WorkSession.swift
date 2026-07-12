import Foundation

enum WorkSessionStatus: Equatable {
    case atWork(arrived: Date, diff8h: TimeInterval, diff830: TimeInterval)
    case away
}

enum WorkSession {
    static let target8h: TimeInterval = 8 * 3600
    static let target830: TimeInterval = 8 * 3600 + 30 * 60

    static func compute(state: String, lastChanged: Date, now: Date) -> WorkSessionStatus {
        guard state == "Work" else { return .away }
        let worked = now.timeIntervalSince(lastChanged)
        return .atWork(arrived: lastChanged, diff8h: worked - target8h, diff830: worked - target830)
    }

    /// Matches the existing HA automation's Telegram message convention:
    /// "+" once worked time has passed the target, "-" while still short of it.
    static func formatDiff(_ diff: TimeInterval) -> String {
        let sign = diff >= 0 ? "+" : "-"
        let totalMinutes = Int(diff.magnitude) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(sign)\(hours)h\(String(format: "%02d", minutes))m"
    }

    static func timeLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    static func targetTime(arrived: Date, target: TimeInterval) -> Date {
        arrived.addingTimeInterval(target)
    }

    static func dateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    /// Formats a completed-session history line ("<date>-<arrived>-<left>-<worked>")
    /// when `current` represents a departure from `previous`, or nil otherwise
    /// (e.g. arrivals aren't logged on their own — only once the session ends).
    static func transitionLogLine(previous: WorkSessionStatus?, current: WorkSessionStatus, now: Date) -> String? {
        guard case .atWork(let arrived, _, _)? = previous, case .away = current else { return nil }
        let worked = now.timeIntervalSince(arrived)
        let workedMinutes = Int(worked) / 60
        let workedLabel = "\(workedMinutes / 60)h\(String(format: "%02d", workedMinutes % 60))m"
        return "\(dateLabel(arrived))-\(timeLabel(arrived))-\(timeLabel(now))-\(workedLabel)"
    }
}
