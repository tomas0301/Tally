import SwiftUI
import SwiftData

@main
struct TallyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Material.self, StudyLog.self, AppSettings.self])
    }
}
