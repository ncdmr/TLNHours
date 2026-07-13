import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var baseURLText: String = ""
    @State private var token: String = ""
    @State private var entityId: String = "person.nic"
    @State private var testResult: TestResult = .idle
    @State private var isTesting = false

    @AppStorage(DisplayPreferenceKey.showArrivalTime) private var showArrivalTime = true
    @AppStorage(DisplayPreferenceKey.show8hCountdown) private var show8hCountdown = true
    @AppStorage(DisplayPreferenceKey.show830Countdown) private var show830Countdown = true
    @AppStorage(DisplayPreferenceKey.targetDisplayMode) private var targetDisplayMode = TargetDisplayMode.countdown
    @AppStorage(DisplayPreferenceKey.menuBarIconOnly) private var menuBarIconOnly = false
    @AppStorage(DisplayPreferenceKey.hardenTokenStorage) private var hardenTokenStorage = true

    enum TestResult: Equatable {
        case idle
        case success
        case failure(String)
    }

    private static let tokenStorageHelpText: String = """
        On: stores the token in the macOS Keychain (more secure). Since this app isn't signed \
        with a Developer ID, macOS may re-prompt for Keychain access after every rebuild.

        Off: stores the token in a plain-text file at ~/.TLNHours.cfg instead (readable only \
        by you, but not encrypted) \u{2014} no prompts.
        """

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Home Assistant Connection")
                .font(.headline)

            TextField("https://ha.example.com", text: $baseURLText)
                .textFieldStyle(.roundedBorder)
            SecureField("Long-lived access token", text: $token)
                .textFieldStyle(.roundedBorder)
            TextField("person.nic", text: $entityId)
                .textFieldStyle(.roundedBorder)

            Toggle("Harden token storage", isOn: $hardenTokenStorage)
                .help(Self.tokenStorageHelpText)

            switch testResult {
            case .idle:
                EmptyView()
            case .success:
                Label("Connection successful", systemImage: "checkmark.circle")
                    .foregroundStyle(.green)
            case .failure(let message):
                Label(message, systemImage: "xmark.circle")
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Test Connection") { Task { await testConnection() } }
                    .disabled(isTesting || baseURLText.isEmpty || token.isEmpty)

                Spacer()

                Button("Cancel") { dismiss() }
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(baseURLText.isEmpty || token.isEmpty)
            }

            Divider()
            displaySection

            #if DEBUG
            Divider()
            mockSection
            #endif

            Divider()
            Button("Quit TLNHours") { NSApplication.shared.terminate(nil) }
        }
        .padding()
        .frame(width: 360)
        .onAppear {
            if let credentials = model.credentials {
                baseURLText = credentials.baseURL.absoluteString
                token = credentials.token
                entityId = credentials.entityId
            }
        }
    }

    private var enabledFieldCount: Int {
        [showArrivalTime, show8hCountdown, show830Countdown].filter { $0 }.count
    }

    @ViewBuilder
    private var displaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Target Format")
                .font(.headline)
            Toggle("Icon only", isOn: $menuBarIconOnly)
            Picker("", selection: $targetDisplayMode) {
                ForEach(TargetDisplayMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Text("Menu Bar Text When at Work")
                .font(.headline)
            Text("The dropdown always shows all three.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Toggle("Arrival time", isOn: $showArrivalTime)
                .disabled(showArrivalTime && enabledFieldCount == 1)
            Toggle("8h target", isOn: $show8hCountdown)
                .disabled(show8hCountdown && enabledFieldCount == 1)
            Toggle("8h30 target", isOn: $show830Countdown)
                .disabled(show830Countdown && enabledFieldCount == 1)
        }
    }

    #if DEBUG
    @ViewBuilder
    private var mockSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Developer: Simulate Work Session")
                .font(.headline)

            Toggle("Enable mock mode", isOn: $model.mockEnabled)

            if model.mockEnabled {
                Toggle("At work", isOn: $model.mockAtWork)

                if model.mockAtWork {
                    Stepper(
                        "Hours worked: \(model.mockHoursWorked, specifier: "%.2f")",
                        value: $model.mockHoursWorked,
                        in: 0...12,
                        step: 0.25
                    )
                }
            }
        }
    }
    #endif

    private func testConnection() async {
        guard let url = URL(string: baseURLText) else {
            testResult = .failure("Invalid URL")
            return
        }
        isTesting = true
        defer { isTesting = false }

        switch await model.testConnection(baseURL: url, token: token, entityId: entityId) {
        case .success:
            testResult = .success
        case .failure(let error):
            testResult = .failure(AppModel.message(for: error))
        }
    }

    private func save() {
        guard let url = URL(string: baseURLText) else {
            testResult = .failure("Invalid URL")
            return
        }
        model.saveCredentials(HACredentials(baseURL: url, token: token, entityId: entityId))
        dismiss()
    }
}
