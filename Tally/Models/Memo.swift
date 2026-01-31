import Foundation
import SwiftData

@Model
final class Memo {
    var id: UUID = UUID()
    var qualificationId: UUID = UUID()
    var materialId: UUID? = nil
    var content: String = ""
    var createdAt: Date = Date()
    
    init(qualificationId: UUID, materialId: UUID? = nil, content: String) {
        self.id = UUID()
        self.qualificationId = qualificationId
        self.materialId = materialId
        self.content = content
        self.createdAt = Date()
    }
}
