import SwiftUI
import PDFKit
import SwiftData
import AVFoundation

@Observable
@MainActor
class ReaderViewModel {
    var book: Book
    var pdfDocument: PDFDocument?
    var currentSelection: PDFSelection?
    var playbackStatus: String = ""
    
    var isRecording: Bool { audioManager.isRecording }
    var recordingDuration: TimeInterval { audioManager.recordingDuration }
    var playbackState: AudioRecorderManager.PlaybackState { audioManager.playbackState }
    var currentPlayingURL: URL? { audioManager.currentPlayingURL }
    var playbackProgress: Double { audioManager.playbackProgress }    
    var playingAnnotationID: UUID? {
        guard let url = currentPlayingURL else { return nil }
        return annotations.first(where: { $0.audioFilePath == url.lastPathComponent })?.id
    }
    
    // Helper to check if a specific note is playing
    func isNotePlaying(_ note: VoiceAnnotation) -> Bool {
        return playbackState == .playing && currentPlayingURL?.lastPathComponent == note.audioFilePath
    }
    
    func isNotePaused(_ note: VoiceAnnotation) -> Bool {
        return playbackState == .paused && currentPlayingURL?.lastPathComponent == note.audioFilePath
    }
    
    var isReadyToRecord: Bool {
        guard let selection = currentSelection else { return false }
        guard let string = selection.string, !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        return true
    }


    private let audioManager = AudioRecorderManager()
    private let fileService = FileService.shared
    
    var annotations: [VoiceAnnotation] = []
    
    private let noteService: VoiceNoteService
    private var modelContext: ModelContext
    
    init(book: Book, modelContext: ModelContext) {
        self.book = book
        self.modelContext = modelContext
        self.noteService = VoiceNoteService(modelContext: modelContext)
        loadDocument()
        fetchAnnotations()
    }
    
    func fetchAnnotations() {
        self.annotations = noteService.fetchAnnotations(for: book.title)
    }
    
    var selectedAnnotation: VoiceAnnotation?
    // This is used to signal the PDFView to scroll to a specific location
    var targetAnnotation: VoiceAnnotation?
    
    func selectAnnotation(_ note: VoiceAnnotation) {
        self.selectedAnnotation = note
        self.targetAnnotation = note // Trigger navigation
    }

    
    func loadDocument() {
        var isStale = false
        do {
            if book.urlData.isEmpty { 
                fetchAnnotations()
                return 
            } 
            
            #if os(macOS)
            let options: URL.BookmarkResolutionOptions = .withSecurityScope
            #else
            let options: URL.BookmarkResolutionOptions = []
            #endif
            
            let url = try URL(resolvingBookmarkData: book.urlData, options: options, relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            if isStale {
                print("Bookmark is stale")
            }
            
            if url.startAccessingSecurityScopedResource() {
                self.pdfDocument = PDFDocument(url: url)
            } else {
                 self.pdfDocument = PDFDocument(url: url)
            }
        } catch {
            print("Failed to resolve bookmark: \(error)")
        }
        
        // Fallback: Try loading directly from Documents if we copied it there
        if self.pdfDocument == nil {
            let fallbackUrl = fileService.getDocumentsDirectory().appendingPathComponent(book.title)
            if FileManager.default.fileExists(atPath: fallbackUrl.path) {
                print("Fallback: Loading from \(fallbackUrl)")
                self.pdfDocument = PDFDocument(url: fallbackUrl)
            }
        }
        
        if self.pdfDocument != nil {
            print("✅ Document loaded successfully for book: \(book.title)")
        } else {
            print("❌ Failed to load document for book: \(book.title)")
        }
    }
    
    func setDocument(url: URL) {
        self.pdfDocument = PDFDocument(url: url)
        fetchAnnotations()
    }
    
    func prepareRecording(for selection: PDFSelection) {
        self.currentSelection = selection
        // We defer actual recording start until the sheet button is pressed or sheet appears
    }
    
    func startRecordingDirectly() {
        Task {
            if await audioManager.requestPermission() {
                 await MainActor.run {
                     audioManager.startRecording()
                 }
            }
        }
    }
    
    func stopRecording() {
        if isRecording {
            if let url = audioManager.stopRecording() {
                saveVoiceNote(audioUrl: url)
            }
        }
    }
    
    private func saveVoiceNote(audioUrl: URL) {
        guard let selection = currentSelection, 
              let page = selection.pages.first else { return }
        
        let pageIndex = pdfDocument?.index(for: page) ?? 0
        
        #if os(macOS)
        let boundsString = NSStringFromRect(selection.bounds(for: page))
        #else
        let boundsString = NSCoder.string(for: selection.bounds(for: page))
        #endif
        
        let filename = audioUrl.lastPathComponent // Only store filename relative to Docs
        let text = selection.string
        
        noteService.saveAnnotation(
            pdfFileName: book.title, 
            pageIndex: pageIndex, 
            bounds: boundsString, 
            audioPath: filename,
            textSnippet: text
        )
        
        fetchAnnotations()
        currentSelection = nil
    }
    
    func playNote(_ note: VoiceAnnotation) {
        let url = fileService.getAudioFileUrl(filename: note.audioFilePath)
        audioManager.playRecording(url: url)
    }
    
    func pausePlayback() {
        audioManager.pausePlayback()
    }
    
    func resumePlayback() {
        audioManager.resumePlayback()
    }
    
    func playVoiceNote(id: UUID) {
        if let note = annotations.first(where: { $0.id == id }) {
            playNote(note)
        }
    }
    
    func deleteNote(_ note: VoiceAnnotation) {
        // 1. Delete audio file
        fileService.deleteAudioFile(filename: note.audioFilePath)
        
        // 2. Delete from database
        noteService.deleteAnnotation(note)
        
        // 3. Refresh list
        fetchAnnotations()
    }
}
