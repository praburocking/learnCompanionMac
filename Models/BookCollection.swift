import Foundation
import SwiftData

@Model
final class BookCollection {
    var id: UUID
    var name: String
    var createdAt: Date
    @Relationship var books: [Book] = []
    
    init(id: UUID = UUID(), name: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}
