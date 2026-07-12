import Foundation

/// Appends and reads plain-text history lines from a local log file.
struct WorkLog {
    let fileURL: URL

    static let headerComment = "# <date>-<time arrived>-<time left>-<worked hours>"

    init(fileURL: URL = WorkLog.defaultFileURL) {
        self.fileURL = fileURL
    }

    static var defaultFileURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".TLNHours.log")
    }

    func append(_ line: String) {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            let data = Data((Self.headerComment + "\n" + line + "\n").utf8)
            try? data.write(to: fileURL)
            return
        }
        let data = Data((line + "\n").utf8)
        guard let handle = try? FileHandle(forWritingTo: fileURL) else { return }
        handle.seekToEndOfFile()
        handle.write(data)
        try? handle.close()
    }

    func read() -> String {
        (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
    }
}
