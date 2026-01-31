import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class QualificationViewModel {
    private var modelContext: ModelContext
    
    var qualifications: [Qualification] = []
    var appSettings: AppSettings?
    
    var selectedQualification: Qualification? {
        qualifications.first { $0.isSelected }
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchAll()
    }
    
    func fetchAll() {
        fetchQualifications()
        fetchAppSettings()
    }
    
    private func fetchQualifications() {
        let descriptor = FetchDescriptor<Qualification>(sortBy: [SortDescriptor(\.createdAt)])
        qualifications = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private func fetchAppSettings() {
        let descriptor = FetchDescriptor<AppSettings>()
        let results = (try? modelContext.fetch(descriptor)) ?? []
        if let settings = results.first {
            appSettings = settings
        } else {
            let settings = AppSettings()
            modelContext.insert(settings)
            save()
            appSettings = settings
        }
    }
    
    // MARK: - Qualification CRUD
    
    func addQualification(name: String, examDate: Date? = nil, weeklyTargetDays: Int = 4, quotaMode: String = "manual") {
        let isFirst = qualifications.isEmpty
        let q = Qualification(name: name, examDate: examDate, weeklyTargetDays: weeklyTargetDays, quotaCalculationMode: quotaMode, isSelected: isFirst)
        modelContext.insert(q)
        if isFirst {
            appSettings?.selectedQualificationId = q.id
        }
        save()
        fetchQualifications()
    }
    
    func updateQualification(_ q: Qualification, name: String, examDate: Date?, weeklyTargetDays: Int, quotaMode: String) {
        q.name = name
        q.examDate = examDate
        q.weeklyTargetDays = weeklyTargetDays
        q.quotaCalculationMode = quotaMode
        save()
        fetchQualifications()
    }
    
    func deleteQualification(_ q: Qualification) {
        let qId = q.id
        let wasSelected = q.isSelected
        
        // 関連するMaterialとStudyLogを削除
        let materialDescriptor = FetchDescriptor<Material>(predicate: #Predicate { $0.qualificationId == qId })
        if let materials = try? modelContext.fetch(materialDescriptor) {
            for material in materials {
                let mId = material.id
                let logDescriptor = FetchDescriptor<StudyLog>(predicate: #Predicate { $0.materialId == mId })
                if let logs = try? modelContext.fetch(logDescriptor) {
                    for log in logs { modelContext.delete(log) }
                }
                modelContext.delete(material)
            }
        }
        
        // 関連するMemoとMemoImageを削除
        let memoDescriptor = FetchDescriptor<Memo>(predicate: #Predicate { $0.qualificationId == qId })
        if let memos = try? modelContext.fetch(memoDescriptor) {
            for memo in memos {
                let memoId = memo.id
                let imgDescriptor = FetchDescriptor<MemoImage>(predicate: #Predicate { $0.memoId == memoId })
                if let imgs = try? modelContext.fetch(imgDescriptor) {
                    for img in imgs { modelContext.delete(img) }
                }
                modelContext.delete(memo)
            }
        }
        
        modelContext.delete(q)
        save()
        fetchQualifications()
        
        // 削除したのが選択中だった場合、最初の資格を選択
        if wasSelected, let first = qualifications.first {
            selectQualification(first)
        }
    }
    
    func selectQualification(_ q: Qualification) {
        for qualification in qualifications {
            qualification.isSelected = (qualification.id == q.id)
        }
        appSettings?.selectedQualificationId = q.id
        save()
        fetchQualifications()
    }
    
    private func save() {
        try? modelContext.save()
    }
}
