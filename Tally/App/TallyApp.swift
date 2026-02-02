import SwiftUI
import SwiftData

@main
struct TallyApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            Qualification.self,
            Material.self,
            StudyLog.self,
            AppSettings.self,
            Memo.self,
            MemoImage.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
