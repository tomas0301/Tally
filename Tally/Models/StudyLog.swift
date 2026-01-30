import Foundation
import SwiftData

@Model
final class StudyLog {
    var id: UUID = UUID()
    var date: Date = Date()
    var materialId: UUID = UUID()
    var amount: Int = 0
    
    init(date: Date, materialId: UUID, amount: Int) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.materialId = materialId
        self.amount = amount
    }
}
