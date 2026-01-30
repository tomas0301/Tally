import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class StudyViewModel {
    private var modelContext: ModelContext
    
    var materials: [Material] = []
    var studyLogs: [StudyLog] = []
    var appSettings: AppSettings?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchAll()
    }
    
    // MARK: - Fetch
    
    func fetchAll() {
        fetchMaterials()
        fetchStudyLogs()
        fetchAppSettings()
    }
    
    func fetchMaterials() {
        let descriptor = FetchDescriptor<Material>(sortBy: [SortDescriptor(\.order), SortDescriptor(\.createdAt)])
        materials = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchStudyLogs() {
        let descriptor = FetchDescriptor<StudyLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        studyLogs = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchAppSettings() {
        let descriptor = FetchDescriptor<AppSettings>()
        let results = (try? modelContext.fetch(descriptor)) ?? []
        if let settings = results.first {
            appSettings = settings
        } else {
            let settings = AppSettings()
            modelContext.insert(settings)
            try? modelContext.save()
            appSettings = settings
        }
    }
    
    // MARK: - Material CRUD
    
    func addMaterial(name: String, totalAmount: Int, unit: String, dailyQuota: Int) {
        let order = materials.count
        let material = Material(name: name, totalAmount: totalAmount, unit: unit, dailyQuota: dailyQuota, order: order)
        modelContext.insert(material)
        save()
        fetchMaterials()
    }
    
    func updateMaterial(_ material: Material, name: String, totalAmount: Int, unit: String, dailyQuota: Int) {
        material.name = name
        material.totalAmount = totalAmount
        material.unit = unit
        material.dailyQuota = dailyQuota
        save()
        fetchMaterials()
    }
    
    func deleteMaterial(_ material: Material) {
        // 関連するStudyLogも削除
        let materialId = material.id
        let predicate = #Predicate<StudyLog> { $0.materialId == materialId }
        let descriptor = FetchDescriptor<StudyLog>(predicate: predicate)
        if let logs = try? modelContext.fetch(descriptor) {
            for log in logs {
                modelContext.delete(log)
            }
        }
        modelContext.delete(material)
        save()
        fetchAll()
    }
    
    // MARK: - Progress Recording
    
    func recordProgress(material: Material, amount: Int) {
        material.currentProgress = min(material.currentProgress + amount, material.totalAmount)
        
        let log = StudyLog(date: Date(), materialId: material.id, amount: amount)
        modelContext.insert(log)
        save()
        fetchAll()
    }
    
    // MARK: - Streak Calculation
    
    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let studyDates = Set(studyLogs.map { calendar.startOfDay(for: $0.date) })
        
        var streak = 0
        var checkDate = today
        
        // 今日学習していなければ昨日から起算
        if !studyDates.contains(today) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
            checkDate = yesterday
        }
        
        while studyDates.contains(checkDate) {
            streak += 1
            guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prevDay
        }
        
        return streak
    }
    
    // MARK: - Weekly Study Days
    
    var weeklyStudyDays: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 今週の月曜日を取得
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        components.weekday = 2 // 月曜日
        guard let monday = calendar.date(from: components) else { return 0 }
        
        let studyDates = Set(studyLogs.map { calendar.startOfDay(for: $0.date) })
        
        var count = 0
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: monday) else { continue }
            if studyDates.contains(date) {
                count += 1
            }
        }
        
        return count
    }
    
    // MARK: - Exam Countdown
    
    var daysUntilExam: Int? {
        guard let examDate = appSettings?.examDate else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let exam = calendar.startOfDay(for: examDate)
        return calendar.dateComponents([.day], from: today, to: exam).day
    }
    
    // MARK: - Daily Quota (Auto Calculation)
    
    func calculatedDailyQuota(for material: Material) -> Int {
        guard appSettings?.quotaCalculationMode == "auto",
              let daysLeft = daysUntilExam, daysLeft > 0,
              let weeklyTarget = appSettings?.weeklyTargetDays, weeklyTarget > 0 else {
            return material.dailyQuota
        }
        
        let remaining = Double(material.remainingAmount)
        let effectiveDays = Double(daysLeft) * Double(weeklyTarget) / 7.0
        guard effectiveDays > 0 else { return material.dailyQuota }
        
        return Int(ceil(remaining / effectiveDays))
    }
    
    // MARK: - Heatmap Data
    
    func heatmapData(months: Int = 4) -> [Date: Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .month, value: -months, to: today) else { return [:] }
        
        var result: [Date: Int] = [:]
        for log in studyLogs {
            let logDate = calendar.startOfDay(for: log.date)
            if logDate >= startDate && logDate <= today {
                result[logDate, default: 0] += log.amount
            }
        }
        return result
    }
    
    // MARK: - Settings
    
    func updateExamDate(_ date: Date?) {
        appSettings?.examDate = date
        save()
    }
    
    func updateWeeklyTargetDays(_ days: Int) {
        appSettings?.weeklyTargetDays = days
        save()
    }
    
    func updateQuotaCalculationMode(_ mode: String) {
        appSettings?.quotaCalculationMode = mode
        save()
    }
    
    // MARK: - Private
    
    private func save() {
        try? modelContext.save()
    }
}
