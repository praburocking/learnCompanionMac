import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    var colorHex: String
    var createdAt: Date
    
    @Relationship(inverse: \VoiceAnnotation.tags)
    var annotations: [VoiceAnnotation]?
    
    init(id: UUID = UUID(), name: String, colorHex: String = "#808080", createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
    }
}
