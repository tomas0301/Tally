import Foundation
import SwiftData

@Model
final class Qualification {
    var id: UUID = UUID()
    var name: String = ""
    var examDate: Date? = nil
    var weeklyTargetDays: Int = 4
    var quotaCalculationMode: String = "manual"
    var createdAt: Date = Date()
    var isSelected: Bool = false
    
    init(name: String, examDate: Date? = nil, weeklyTargetDays: Int = 4, quotaCalculationMode: String = "manual", isSelected: Bool = false) {
        self.id = UUID()
        self.name = name
        self.examDate = examDate
        self.weeklyTargetDays = weeklyTargetDays
        self.quotaCalculationMode = quotaCalculationMode
        self.createdAt = Date()
        self.isSelected = isSelected
    }
}
