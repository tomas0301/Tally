import Foundation
import SwiftData

@Model
final class AppSettings {
    var id: UUID = UUID()
    var examDate: Date? = nil
    var weeklyTargetDays: Int = 4
    var quotaCalculationMode: String = "manual"
    
    init() {
        self.id = UUID()
        self.examDate = nil
        self.weeklyTargetDays = 4
        self.quotaCalculationMode = "manual"
    }
}
