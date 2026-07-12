import SwiftUI

@main
struct TLNHoursApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(model: model)
        } label: {
            MenuBarLabel(model: model)
        }
        .menuBarExtraStyle(.window)

        Window("TLN Hours Settings", id: "settings") {
            SettingsView(model: model)
        }
        .windowResizability(.contentSize)

        Window("TLN Hours History", id: "history") {
            HistoryView()
        }
        .windowResizability(.contentSize)
    }
}
