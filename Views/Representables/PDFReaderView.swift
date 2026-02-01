import SwiftUI
import PDFKit
import Foundation

#if os(iOS)
struct PDFReaderView: UIViewRepresentable {
    let document: PDFDocument?
    @Binding var selection: PDFSelection?
    var annotations: [VoiceAnnotation]
    var targetAnnotation: VoiceAnnotation?
    var onTapAnnotationGroup: (([VoiceAnnotation], CGRect) -> Void)?
    var onAddVoiceNote: ((PDFSelection) -> Void)?
    var playingId: UUID? // Binding not strictly needed if we just pass value, but parent view refreshes.
    
    typealias UIViewType = CustomPDFView
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> CustomPDFView {
        let pdfView = CustomPDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemGray6
        pdfView.minScaleFactor = 0.5
        pdfView.maxScaleFactor = 5.0
        
        pdfView.delegate = context.coordinator
        pdfView.customDelegate = context.coordinator

        return pdfView
    }
    
    func updateUIView(_ uiView: CustomPDFView, context: Context) {
        if uiView.document != document {
            uiView.document = document
            uiView.autoScales = true
        }
        
        // Navigation Logic
        if let target = targetAnnotation {
            context.coordinator.navigateToAnnotation(target, in: uiView)
        }
        
        // Sync Annotations (Highlight + Bubbles)
        context.coordinator.updateAnnotations(in: uiView, annotations: annotations)
        
        // Highlight active note
        context.coordinator.updateHighlighting(in: uiView, playingId: playingId)
    }
    
    // ...
    
    class Coordinator: NSObject, PDFViewDelegate, CustomPDFViewDelegate {
        var parent: PDFReaderView
        private var lastNavigatedId: UUID?
        private var overlayManager = VoiceNoteOverlayManager()
        
        init(_ parent: PDFReaderView) {
            self.parent = parent
            super.init()
            NotificationCenter.default.addObserver(self, selector: #selector(selectionChanged), name: .PDFViewSelectionChanged, object: nil)
            
            // Setup bubble tap handler
            overlayManager.onBubbleTap = { [weak self] group, sourceView in
                guard let self = self, let view = sourceView as? UIView else { return }
                // Convert view frame to global or suitable coordinate space? 
                let globalRect = view.convert(view.bounds, to: nil) // Window coords
                self.parent.onTapAnnotationGroup?(group.annotations, globalRect)
            }
        }
        
        func calculateDestination(for note: VoiceAnnotation, in pdfView: PDFView) -> PDFDestination? {
            guard let document = pdfView.document,
                  let page = document.page(at: note.pageIndex) else { return nil }
            
            #if os(macOS)
            let rect = NSRectFromString(note.selectionBounds)
            #else
            let rect = NSCoder.cgRect(for: note.selectionBounds)
            #endif
            return PDFDestination(page: page, at: CGPoint(x: rect.origin.x, y: rect.maxY))
        }
        
        func navigateToAnnotation(_ note: VoiceAnnotation, in pdfView: PDFView) {
            guard lastNavigatedId != note.id else { return }
            
            if let destination = calculateDestination(for: note, in: pdfView) {
                pdfView.go(to: destination)
            }
            lastNavigatedId = note.id
        }
        
        @objc func selectionChanged(_ notification: Notification) {
            if let pdfView = notification.object as? PDFView {
                parent.selection = pdfView.currentSelection
            }
        }
        
        // Restore Delegate Method
        func didRequestAddVoiceNote(selection: PDFSelection) {
            parent.onAddVoiceNote?(selection)
        }
        
        func updateAnnotations(in pdfView: PDFView, annotations: [VoiceAnnotation]) {
             guard let document = pdfView.document else { return }
             
             // 1. Manage Highlights (Native Annotations)
             for pageIndex in 0..<document.pageCount {
                 guard let page = document.page(at: pageIndex) else { continue }
                 let toRemove = page.annotations.filter { $0 is VoicePDFAnnotation }
                 toRemove.forEach { page.removeAnnotation($0) }
             }
             
             // ... add new ...
             for note in annotations {
                 guard let page = document.page(at: note.pageIndex) else { continue }
                 #if os(macOS)
                 let rect = NSRectFromString(note.selectionBounds)
                 #else
                 let rect = NSCoder.cgRect(for: note.selectionBounds)
                 #endif
                 let annotation = VoicePDFAnnotation(bounds: rect, id: note.id)
                 page.addAnnotation(annotation)
             }
             
             // 2. Manage Bubbles (Overlay)
             overlayManager.update(pdfView: pdfView, annotations: annotations) { id in
                 // Playback handled via tap
             }
        }
        
        func updateHighlighting(in pdfView: PDFView, playingId: UUID?) {
             guard let document = pdfView.document else { return }
             
             for pageIndex in 0..<document.pageCount {
                 guard let page = document.page(at: pageIndex) else { continue }
                 
                 for annotation in page.annotations {
                     if let voiceAnno = annotation as? VoicePDFAnnotation {
                         if voiceAnno.voiceAnnotationID == playingId {
                             // Active
                             voiceAnno.color = .yellow.withAlphaComponent(0.5)
                         } else {
                             // Inactive
                             voiceAnno.color = .purple.withAlphaComponent(0.3)
                         }
                     }
                 }
             }
        }
    }
}
#elseif os(macOS)
struct PDFReaderView: NSViewRepresentable {
    let document: PDFDocument?
    @Binding var selection: PDFSelection?
    var annotations: [VoiceAnnotation]
    var targetAnnotation: VoiceAnnotation?
    var onTapAnnotationGroup: (([VoiceAnnotation], CGRect) -> Void)?
    var onAddVoiceNote: ((PDFSelection) -> Void)?
    var playingId: UUID?

    func makeNSView(context: Context) -> CustomPDFView {
        let pdfView = CustomPDFView()
        pdfView.autoScales = true
        pdfView.delegate = context.coordinator
        pdfView.customDelegate = context.coordinator
        
        let tapGesture = NSClickGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        pdfView.addGestureRecognizer(tapGesture)
        
        return pdfView
    }

    func updateNSView(_ nsView: CustomPDFView, context: Context) {
        if nsView.document != document {
            nsView.document = document
        }
        
        // Navigation Logic
        if let target = targetAnnotation {
            context.coordinator.navigateToAnnotation(target, in: nsView)
        }
        
        updateAnnotations(in: nsView)
    }
    
    private func updateAnnotations(in pdfView: PDFView) {
        guard let document = pdfView.document else { return }
        
        // 1. Remove existing VoicePDFAnnotations
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            for annotation in page.annotations {
                if annotation is VoicePDFAnnotation {
                    page.removeAnnotation(annotation)
                }
            }
        }
        
        // 2. Add new ones
        for note in annotations {
            guard let page = document.page(at: note.pageIndex) else { continue }
            let rect = NSRectFromString(note.selectionBounds)
            let annotation = VoicePDFAnnotation(bounds: rect, id: note.id)
            page.addAnnotation(annotation)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PDFViewDelegate, CustomPDFViewDelegate {
        var parent: PDFReaderView
        private var lastNavigatedId: UUID?
        
        init(_ parent: PDFReaderView) {
            self.parent = parent
            super.init()
            NotificationCenter.default.addObserver(self, selector: #selector(selectionChanged), name: .PDFViewSelectionChanged, object: nil)
        }
        
        func navigateToAnnotation(_ note: VoiceAnnotation, in pdfView: PDFView) {
             guard lastNavigatedId != note.id else { return }
             
             guard let document = pdfView.document,
                   let page = document.page(at: note.pageIndex) else { return }
             
             let rect = NSRectFromString(note.selectionBounds)
             // Create destination. Y coordinate in PDF is usually bottom-up, but NSRect might be top-down depending on how we saved it?
             // PDFKit coordinate system is bottom-left origin.
             // If we saved NSRect from Quartz, it's bottom-left. 
             // Let's assume standard PDF coordinates.
             let destination = PDFDestination(page: page, at: CGPoint(x: rect.origin.x, y: rect.maxY))
             
             // Move to page
             pdfView.go(to: destination)
             
             lastNavigatedId = note.id
         }
        
        @objc func selectionChanged(_ notification: Notification) {
             if let pdfView = notification.object as? PDFView {
                // Must be careful about thread safety with PDFView updates
                DispatchQueue.main.async {
                    self.parent.selection = pdfView.currentSelection
                }
            }
        }
        
        func didRequestAddVoiceNote(selection: PDFSelection) {
            parent.onAddVoiceNote?(selection)
        }
        
        @objc func handleTap(_ gesture: NSClickGestureRecognizer) {
           guard let pdfView = gesture.view as? PDFView else { return }
           let location = gesture.location(in: pdfView)
           
           if let page = pdfView.page(for: location, nearest: true) {
               let locationInPage = pdfView.convert(location, to: page)
                // if let annotation = page.annotation(at: locationInPage) as? VoicePDFAnnotation {
                //    parent.onPlayAnnotation?(annotation.voiceAnnotationID)
                // }
           }
       }
    }
}
#endif
