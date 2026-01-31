import Foundation
import SwiftData

@Model
final class MemoImage {
    var id: UUID = UUID()
    var memoId: UUID = UUID()
    @Attribute(.externalStorage) var imageData: Data = Data()
    var order: Int = 0
    var createdAt: Date = Date()
    
    init(memoId: UUID, imageData: Data, order: Int = 0) {
        self.id = UUID()
        self.memoId = memoId
        self.imageData = imageData
        self.order = order
        self.createdAt = Date()
    }
}
