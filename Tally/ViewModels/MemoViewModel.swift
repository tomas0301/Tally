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
        let memo = Memo(qualificationId: qualificationId, materialId: materialId, content: content)
        modelContext.insert(memo)
        
        for (index, image) in images.enumerated() {
            if let data = image.jpegData(compressionQuality: 0.7) {
                let memoImage = MemoImage(memoId: memo.id, imageData: data, order: index)
                modelContext.insert(memoImage)
            }
        }
        
        save()
        load(for: qualificationId)
    }
    
    func deleteMemo(_ memo: Memo) {
        let qId = memo.qualificationId
        let memoId = memo.id
        
        // 関連画像を削除
        let descriptor = FetchDescriptor<MemoImage>(predicate: #Predicate { $0.memoId == memoId })
        if let images = try? modelContext.fetch(descriptor) {
            for img in images {
                modelContext.delete(img)
            }
        }
        
        modelContext.delete(memo)
        save()
        load(for: qId)
    }
    
    func imagesForMemo(_ memo: Memo) -> [Data] {
        let memoId = memo.id
        let descriptor = FetchDescriptor<MemoImage>(
            predicate: #Predicate { $0.memoId == memoId },
            sortBy: [SortDescriptor(\.order)]
        )
        let results = (try? modelContext.fetch(descriptor)) ?? []
        return results.map(\.imageData)
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
