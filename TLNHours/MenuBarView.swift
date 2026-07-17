import SwiftUI

struct MenuBarLabel: View {
    @ObservedObject var model: AppModel

    @AppStorage(DisplayPreferenceKey.showArrivalTime) private var showArrivalTime = true
    @AppStorage(DisplayPreferenceKey.show8hCountdown) private var show8hCountdown = true
    @AppStorage(DisplayPreferenceKey.show830Countdown) private var show830Countdown = true
    @AppStorage(DisplayPreferenceKey.targetDisplayMode) private var targetDisplayMode = TargetDisplayMode.countdown
    @AppStorage(DisplayPreferenceKey.menuBarIconOnly) private var menuBarIconOnly = false

    var body: some View {
        switch model.status {
        case .atWork(let arrived, let diff8h, let diff830):
            if menuBarIconOnly {
                if model.connectionError != nil {
                    Image(systemName: "exclamationmark.triangle")
                } else {
                    Image(systemName: "briefcase")
                }
            } else if let text = compactText(arrived: arrived, diff8h: diff8h, diff830: diff830) {
                if model.connectionError != nil {
                    Label(text, systemImage: "exclamationmark.triangle")
                } else {
                    Text(text)
                }
            } else {
                Image(systemName: "briefcase")
            }
        case .away:
            if model.credentials == nil {
                Image(systemName: "gearshape")
            } else if model.connectionError != nil {
                Image(systemName: "exclamationmark.triangle")
            } else {
                Image(systemName: "briefcase")
            }
        }
    }

    private func compactText(arrived: Date, diff8h: TimeInterval, diff830: TimeInterval) -> String? {
        var parts: [String] = []
        if showArrivalTime {
            parts.append(WorkSession.timeLabel(arrived))
        }

        var targetParts: [String] = []
        switch targetDisplayMode {
        case .countdown:
            if show8hCountdown { targetParts.append(WorkSession.formatDiff(diff8h)) }
            if show830Countdown { targetParts.append(WorkSession.formatDiff(diff830)) }
        case .leaveTime:
            if show8hCountdown {
                targetParts.append(WorkSession.timeLabel(WorkSession.targetTime(arrived: arrived, target: WorkSession.target8h)))
            }
            if show830Countdown {
                targetParts.append(WorkSession.timeLabel(WorkSession.targetTime(arrived: arrived, target: WorkSession.target830)))
            }
        }
        if !targetParts.isEmpty {
            parts.append(targetParts.joined(separator: " / "))
        }

        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

struct MenuBarContentView: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch model.status {
            case .atWork(let arrived, let diff8h, let diff830):
                VStack(alignment: .leading, spacing: 4) {
                    Text("Arrived at \(WorkSession.timeLabel(arrived))")
                        .font(.headline)
                    Text(targetLine(label: "8h", arrived: arrived, target: WorkSession.target8h, diff: diff8h))
                    Text(targetLine(label: "8h30", arrived: arrived, target: WorkSession.target830, diff: diff830))
                }
            case .away:
                Text("Not at work")
                    .font(.headline)
            }

            if let error = model.connectionError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Divider()

            HStack {
                Button("History…") {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    openWindow(id: "history")
                }
                Button("Settings…") {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    openWindow(id: "settings")
                }
            }
        }
        .padding()
        .frame(minWidth: 220)
    }

    private func targetLine(label: String, arrived: Date, target: TimeInterval, diff: TimeInterval) -> String {
        let leaveTime = WorkSession.timeLabel(WorkSession.targetTime(arrived: arrived, target: target))
        return "\(label): leave at \(leaveTime) \u{00b7} \(WorkSession.remainingLabel(diff))"
    }
}
