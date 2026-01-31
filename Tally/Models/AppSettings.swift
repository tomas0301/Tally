import Foundation
import SwiftData

@Model
final class AppSettings {
    var id: UUID = UUID()
    var selectedQualificationId: UUID? = nil
    
    init() {
        self.id = UUID()
        self.selectedQualificationId = nil
    }
}
