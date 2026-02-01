import Foundation
import SwiftData

@Model
final class Book {
    var id: UUID
    var title: String
    var urlData: Data // Bookmark data for security scoped access
    var createdAt: Date
    @Relationship(inverse: \BookCollection.books) var collection: BookCollection?

    init(id: UUID = UUID(), title: String, urlData: Data, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.urlData = urlData
        self.createdAt = createdAt
    }
}
