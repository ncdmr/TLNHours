import Foundation

/// Parses Home Assistant's ISO 8601 timestamps, e.g. "2026-07-10T17:18:13.205962+02:00".
enum HATimestamp {
    private static func makeFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter
    }

    private static let withFraction = makeFormatter("yyyy-MM-dd'T'HH:mm:ss.SSSSSSxxxxx")
    private static let withoutFraction = makeFormatter("yyyy-MM-dd'T'HH:mm:ssxxxxx")

    static func parse(_ string: String) -> Date? {
        withFraction.date(from: string) ?? withoutFraction.date(from: string)
    }
}
