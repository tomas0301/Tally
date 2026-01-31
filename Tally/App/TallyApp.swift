import SwiftUI
import SwiftData

@main
struct TallyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Qualification.self, Material.self, StudyLog.self, AppSettings.self, Memo.self])
    }
}
