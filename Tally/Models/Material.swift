import Foundation
import SwiftData

@Model
final class Material {
    var id: UUID = UUID()
    var qualificationId: UUID = UUID()
    var name: String = ""
    var totalAmount: Int = 0
    var currentProgress: Int = 0
    var unit: String = "ページ" // "ページ" or "問" or "時間"
    var dailyQuota: Int = 0
    var quotaMode: String = "manual" // "auto" or "manual"
    var deadline: Date? = nil
    var useWeeklyTarget: Bool = false
    var order: Int = 0
    var createdAt: Date = Date()
    
    init(qualificationId: UUID, name: String, totalAmount: Int, unit: String, dailyQuota: Int, order: Int = 0) {
        self.id = UUID()
        self.qualificationId = qualificationId
        self.name = name
        self.totalAmount = totalAmount
        self.currentProgress = 0
        self.unit = unit
        self.dailyQuota = dailyQuota
        self.order = order
        self.createdAt = Date()
    }
    
    var progressRate: Double {
        guard totalAmount > 0 else { return 0 }
        return Double(currentProgress) / Double(totalAmount)
    }
    
    var progressPercent: Int {
        Int(progressRate * 100)
    }
    
    var remainingAmount: Int {
        max(0, totalAmount - currentProgress)
    }
}
