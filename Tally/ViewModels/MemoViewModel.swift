import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class MemoViewModel {
    private var modelContext: ModelContext
    
    var memos: [Memo] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func load(for qualificationId: UUID?) {
        guard let qId = qualificationId else {
            memos = []
            return
        }
        let descriptor = FetchDescriptor<Memo>(
            predicate: #Predicate { $0.qualificationId == qId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        memos = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func addMemo(qualificationId: UUID, materialId: UUID?, content: String, images: [UIImage]) {
        var fileNames: [String] = []
        for image in images {
            if let name = ImageStorage.save(image: image) {
                fileNames.append(name)
            }
        }
        let memo = Memo(qualificationId: qualificationId, materialId: materialId, content: content, imageFileNames: fileNames)
        modelContext.insert(memo)
        save()
        load(for: qualificationId)
    }
    
    func deleteMemo(_ memo: Memo) {
        let qId = memo.qualificationId
        for fileName in memo.imageFileNames {
            ImageStorage.delete(fileName: fileName)
        }
        modelContext.delete(memo)
        save()
        load(for: qId)
    }
    
    func materials(for qualificationId: UUID?) -> [Material] {
        guard let qId = qualificationId else { return [] }
        let descriptor = FetchDescriptor<Material>(predicate: #Predicate { $0.qualificationId == qId })
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private func save() {
        try? modelContext.save()
    }
}
