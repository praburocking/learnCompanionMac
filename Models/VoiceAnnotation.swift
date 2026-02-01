import Foundation
import SwiftData

@Model
final class VoiceAnnotation {
    var id: UUID
    var pdfFileName: String
    var pageIndex: Int
    var selectionBounds: String // Stored as String representation of CGRect
    var audioFilePath: String // Relative path
    var createdAt: Date
    var textSnippet: String?
    
    @Relationship
    var tags: [Tag]?

    init(id: UUID = UUID(), pdfFileName: String, pageIndex: Int, selectionBounds: String, audioFilePath: String, textSnippet: String? = nil, tags: [Tag] = [], createdAt: Date = Date()) {
        self.id = id
        self.pdfFileName = pdfFileName
        self.pageIndex = pageIndex
        self.selectionBounds = selectionBounds
        self.audioFilePath = audioFilePath
        self.textSnippet = textSnippet
        self.tags = tags
        self.createdAt = createdAt
    }
}
