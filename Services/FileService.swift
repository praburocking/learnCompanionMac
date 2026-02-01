import Foundation
import SwiftData

class FileService {
    static let shared = FileService()
    
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func savePDF(from url: URL) throws -> URL {
        let fileName = url.lastPathComponent
        let destination = getDocumentsDirectory().appendingPathComponent(fileName)
        
        // If file exists, we might want to rename or overwrite. 
        // For simplicity, overwrite if needed or usage unique names.
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        
        // Handling security scoped resources if needed
        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            try FileManager.default.copyItem(at: url, to: destination)
        } else {
            // Try direct copy
            try FileManager.default.copyItem(at: url, to: destination)
        }
        
        return destination
    }
    
    func generateUniqueAudioFilename() -> String {
        return "voice_note_\(UUID().uuidString).m4a"
    }
    
    func getAudioFileUrl(filename: String) -> URL {
        return getDocumentsDirectory().appendingPathComponent(filename)
    }
    
    func deleteAudioFile(filename: String) {
        let url = getAudioFileUrl(filename: filename)
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
                print("Deleted audio file: \(url.lastPathComponent)")
            }
        } catch {
            print("Failed to delete audio file: \(error)")
        }
    }
}
