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
        #if targetEnvironment(simulator)
        let cloudKit: ModelConfiguration.CloudKitDatabase = .none
        #else
        let cloudKit: ModelConfiguration.CloudKitDatabase = .automatic
        #endif
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: cloudKit
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
