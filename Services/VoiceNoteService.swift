import Foundation
import SwiftData

@MainActor
class VoiceNoteService {
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetchAnnotations(for pdfFileName: String) -> [VoiceAnnotation] {
        do {
            let descriptor = FetchDescriptor<VoiceAnnotation>(
                predicate: #Predicate { $0.pdfFileName == pdfFileName },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch annotations: \(error)")
            return []
        }
    }
    
    func saveAnnotation(pdfFileName: String, pageIndex: Int, bounds: String, audioPath: String, textSnippet: String? = nil) {
        let annotation = VoiceAnnotation(
            pdfFileName: pdfFileName,
            pageIndex: pageIndex,
            selectionBounds: bounds,
            audioFilePath: audioPath,
            textSnippet: textSnippet
        )
        modelContext.insert(annotation)
        
        do {
            try modelContext.save()
            print("Saved annotation for \(pdfFileName)")
        } catch {
            print("Failed to save annotation: \(error)")
        }
    }
    
    func deleteAnnotation(_ annotation: VoiceAnnotation) {
        modelContext.delete(annotation)
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete annotation: \(error)")
        }
    }
}
