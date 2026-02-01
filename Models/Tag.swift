import Foundation
import SwiftData

@Model
final class Tag {
    var name: String
    var colorHex: String
    var createdAt: Date
    
    @Relationship(inverse: \VoiceAnnotation.tags)
    var annotations: [VoiceAnnotation]?
    
    init(name: String, colorHex: String = "#808080", createdAt: Date = Date()) {
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
    }
}
