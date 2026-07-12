import AppKit
import Foundation
import ServiceManagement

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var status: WorkSessionStatus = .away
    @Published private(set) var connectionError: String?
    @Published private(set) var credentials: HACredentials?

    #if DEBUG
    @Published var mockEnabled = false { didSet { triggerImmediatePoll() } }
    @Published var mockAtWork = true { didSet { triggerImmediatePoll() } }
    @Published var mockHoursWorked: Double = 2.0 { didSet { triggerImmediatePoll() } }
    #endif

    private var pollTask: Task<Void, Never>?
    private var wakeObserver: NSObjectProtocol?
    private var lastKnownArrival: Date?
    private let workLog = WorkLog()
    private let plainFileStore = PlainFileCredentialsStore()

    private static let pollInterval: UInt64 = 60_000_000_000 // 60s in nanoseconds

    /// Whether the access token is stored in the Keychain (more secure, but
    /// this app's ad-hoc code signature changes on every rebuild, which can
    /// trigger repeated Keychain-access prompts) or in a plain-text file at
    /// ~/.TLNHours.cfg (no prompts, less secure).
    private var hardenTokenStorage: Bool {
        UserDefaults.standard.object(forKey: DisplayPreferenceKey.hardenTokenStorage) as? Bool ?? true
    }

    init() {
        credentials = hardenTokenStorage
            ? (KeychainStore.load() ?? plainFileStore.load())
            : (plainFileStore.load() ?? KeychainStore.load())
        registerLoginItem()
        observeWake()
        pollTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                await self.poll()
                try? await Task.sleep(nanoseconds: Self.pollInterval)
            }
        }
    }

    deinit {
        pollTask?.cancel()
        if let wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
    }

    func saveCredentials(_ credentials: HACredentials) {
        if hardenTokenStorage {
            KeychainStore.save(credentials)
            plainFileStore.clear()
        } else {
            plainFileStore.save(credentials)
            KeychainStore.clear()
        }
        self.credentials = credentials
        Task { await poll() }
    }

    func testConnection(baseURL: URL, token: String, entityId: String) async -> Result<Void, HAClientError> {
        let client = HAClient(baseURL: baseURL, token: token)
        switch await client.fetchPersonState(entityId: entityId) {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }

    func poll() async {
        #if DEBUG
        if mockEnabled {
            connectionError = nil
            if mockAtWork {
                let arrived = Date().addingTimeInterval(-mockHoursWorked * 3600)
                status = WorkSession.compute(state: "Work", lastChanged: arrived, now: Date())
            } else {
                status = .away
            }
            return
        }
        #endif

        guard let credentials else {
            status = .away
            connectionError = nil
            return
        }

        let client = HAClient(baseURL: credentials.baseURL, token: credentials.token)
        switch await client.fetchPersonState(entityId: credentials.entityId) {
        case .success(let person):
            connectionError = nil
            lastKnownArrival = person.state == "Work" ? person.lastChanged : nil
            let newStatus = WorkSession.compute(state: person.state, lastChanged: person.lastChanged, now: Date())
            if let line = WorkSession.transitionLogLine(previous: status, current: newStatus, now: Date()) {
                workLog.append(line)
            }
            status = newStatus
        case .failure(let error):
            connectionError = Self.message(for: error)
            // Keep the countdown ticking locally from the last known-good arrival
            // time so a transient HA/proxy outage doesn't blank the display.
            if let arrival = lastKnownArrival {
                status = WorkSession.compute(state: "Work", lastChanged: arrival, now: Date())
            }
        }
    }

    #if DEBUG
    private func triggerImmediatePoll() {
        Task { await poll() }
    }
    #endif

    private func registerLoginItem() {
        do {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } catch {
            // Non-fatal: user can still enable it manually via System Settings > Login Items.
        }
    }

    private func observeWake() {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in await self?.poll() }
        }
    }

    static func message(for error: HAClientError) -> String {
        switch error {
        case .invalidURL: return "Invalid HA URL"
        case .unauthorized: return "Invalid access token"
        case .network(let message): return "Network error: \(message)"
        case .unexpectedResponse(let code): return "HA returned status \(code)"
        case .decoding: return "Could not parse HA response"
        }
    }
}
