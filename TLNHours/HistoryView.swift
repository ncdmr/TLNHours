import SwiftUI

struct HistoryView: View {
    private let workLog = WorkLog()
    @State private var lines: [String] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                if lines.isEmpty {
                    Text("No history yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 420, height: 320)
        .onAppear(perform: reload)
    }

    private func reload() {
        lines = workLog.read()
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.hasPrefix("#") }
            .reversed()
    }
}
