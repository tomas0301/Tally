import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class HomeViewModel {
    private var modelContext: ModelContext
    
    var materials: [Material] = []
    var studyLogs: [StudyLog] = []
    var selectedQualification: Qualification?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Load
    
    func load(for qualification: Qualification?) {
        self.selectedQualification = qualification
        fetchMaterials()
        fetchStudyLogs()
    }
    
    func fetchMaterials() {
        guard let qId = selectedQualification?.id else {
            materials = []
            return
        }
        let descriptor = FetchDescriptor<Material>(
            predicate: #Predicate { $0.qualificationId == qId },
            sortBy: [SortDescriptor(\.order), SortDescriptor(\.createdAt)]
        )
        materials = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func fetchStudyLogs() {
        guard selectedQualification != nil else {
            studyLogs = []
            return
        }
        let materialIds = materials.map(\.id)
        let descriptor = FetchDescriptor<StudyLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let allLogs = (try? modelContext.fetch(descriptor)) ?? []
        studyLogs = allLogs.filter { materialIds.contains($0.materialId) }
    }
    
    // MARK: - Material CRUD
    
    func addMaterial(name: String, totalAmount: Int, unit: String, dailyQuota: Int, quotaMode: String = "manual", deadline: Date? = nil, useWeeklyTarget: Bool = false) {
        guard let qId = selectedQualification?.id else { return }
        let order = materials.count
        let material = Material(qualificationId: qId, name: name, totalAmount: totalAmount, unit: unit, dailyQuota: dailyQuota, order: order)
        material.quotaMode = quotaMode
        material.deadline = deadline
        material.useWeeklyTarget = useWeeklyTarget
        modelContext.insert(material)
        save()
        fetchMaterials()
    }
    
    func updateMaterial(_ material: Material, name: String, totalAmount: Int, unit: String, dailyQuota: Int, quotaMode: String = "manual", deadline: Date? = nil, useWeeklyTarget: Bool = false) {
        material.name = name
        material.totalAmount = totalAmount
        material.unit = unit
        material.dailyQuota = dailyQuota
        material.quotaMode = quotaMode
        material.deadline = deadline
        material.useWeeklyTarget = useWeeklyTarget
        save()
        fetchMaterials()
    }
    
    func deleteMaterial(_ material: Material) {
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
        fetchMaterials()
        fetchStudyLogs()
    }
    
    // MARK: - Progress
    
    func recordProgress(material: Material, amount: Int) {
        material.currentProgress = min(material.currentProgress + amount, material.totalAmount)
        let log = StudyLog(date: Date(), materialId: material.id, amount: amount)
        modelContext.insert(log)
        save()
        fetchMaterials()
        fetchStudyLogs()
    }
    
    // MARK: - Streak
    
    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let studyDates = Set(studyLogs.map { calendar.startOfDay(for: $0.date) })
        
        var streak = 0
        var checkDate = today
        
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
    
    // MARK: - Weekly
    
    var weeklyStudyDays: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        components.weekday = 2
        guard let monday = calendar.date(from: components) else { return 0 }
        
        let studyDates = Set(studyLogs.map { calendar.startOfDay(for: $0.date) })
        var count = 0
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: monday) else { continue }
            if studyDates.contains(date) { count += 1 }
        }
        return count
    }
    
    // MARK: - Exam Countdown
    
    var daysUntilExam: Int? {
        guard let examDate = selectedQualification?.examDate else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let exam = calendar.startOfDay(for: examDate)
        return calendar.dateComponents([.day], from: today, to: exam).day
    }
    
    // MARK: - Daily Quota
    
    func calculatedDailyQuota(for material: Material) -> Int {
        // Per-material auto mode
        if material.quotaMode == "auto" {
            let deadlineDate = material.deadline ?? selectedQualification?.examDate
            guard let deadline = deadlineDate else { return material.dailyQuota }
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let target = calendar.startOfDay(for: deadline)
            let daysLeft = calendar.dateComponents([.day], from: today, to: target).day ?? 0
            guard daysLeft > 0 else { return material.remainingAmount }
            let remaining = Double(material.remainingAmount)
            if material.useWeeklyTarget {
                let weeklyTarget = selectedQualification?.weeklyTargetDays ?? 7
                let effectiveDays = max(1.0, Double(daysLeft) * Double(weeklyTarget) / 7.0)
                return Int(ceil(remaining / effectiveDays))
            } else {
                return Int(ceil(remaining / Double(daysLeft)))
            }
        }
        // Legacy: qualification-level auto mode (backward compat)
        if selectedQualification?.quotaCalculationMode == "auto" {
            if let daysLeft = daysUntilExam, daysLeft > 0,
               let weeklyTarget = selectedQualification?.weeklyTargetDays, weeklyTarget > 0 {
                let remaining = Double(material.remainingAmount)
                let effectiveDays = Double(daysLeft) * Double(weeklyTarget) / 7.0
                if effectiveDays > 0 {
                    return Int(ceil(remaining / effectiveDays))
                }
            }
        }
        return material.dailyQuota
    }

    func todayAmount(for material: Material) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return studyLogs
            .filter { $0.materialId == material.id && calendar.startOfDay(for: $0.date) == today }
            .reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Heatmap
    
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
    
    private func save() {
        do {
            try modelContext.save()
            print("✅ HomeViewModel: 保存成功")
        } catch {
            print("❌ HomeViewModel: 保存失敗 - \(error)")
        }
    }
}
