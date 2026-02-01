import SwiftUI
import PDFKit

#if os(iOS)
import UIKit
#else
import AppKit
#endif

class VoiceNoteOverlayManager: NSObject {
    private var iconHostingControllers: [UUID: Any] = [:] // Map GroupID -> HostingController
    private var activeGroups: [AnnotationGroup] = []
    
    // Struct to represent a cluster of annotations
    struct AnnotationGroup: Identifiable {
        let id = UUID()
        var annotations: [VoiceAnnotation]
        var pageIndex: Int
        var avgY: CGFloat
        
        var primaryAnnotation: VoiceAnnotation? { annotations.first }
    }
    
    // Callback closure to be set by parent
    var onBubbleTap: ((AnnotationGroup, Any) -> Void)? // Group, SourceView (for anchor)
    
    func update(pdfView: PDFView, annotations: [VoiceAnnotation], onPlay: @escaping (UUID) -> Void) {
        #if os(iOS)
        // 1. Group Annotations (Simple proximity clustering)
        let groups = clusterAnnotations(annotations, pdfView: pdfView)
        self.activeGroups = groups
        
        guard let documentView = pdfView.documentView else { return }
        
        // 2. Reconcile Views
        // For simplicity: Remove all custom bubbles and re-add.
        documentView.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }
        
        for group in groups {
            guard let first = group.primaryAnnotation,
                  let page = pdfView.document?.page(at: first.pageIndex) else { continue }
            
            // Calculate Position
            let boundsString = first.selectionBounds
            let pageRect = NSCoder.cgRect(for: boundsString)
            
            // Convert to DocumentView coordinates
            let viewRect = pdfView.convert(pageRect, from: page)
            let docRect = pdfView.convert(viewRect, to: documentView)
            
            // Margin Position:
            let xPosition = docRect.maxX + 10
            let yPosition = docRect.midY - 16 // Center 32pt icon
            
            // Create View
            let iconView = MarginAnnotationIcon(count: group.annotations.count, isSelected: false)
            let controller = UIHostingController(rootView: iconView)
            controller.view.backgroundColor = .clear
            controller.view.frame = CGRect(x: xPosition, y: yPosition, width: 32, height: 32)
            controller.view.tag = 999 
            
            // Interaction
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            controller.view.addGestureRecognizer(tap)
            controller.view.accessibilityValue = group.id.uuidString
            
            // Add to hierarchy
            documentView.addSubview(controller.view)
        }
        #endif
    }
    
    #if os(iOS)
    // Simple clustering logic
    private func clusterAnnotations(_ annotations: [VoiceAnnotation], pdfView: PDFView) -> [AnnotationGroup] {
        // Group by page
        let byPage = Dictionary(grouping: annotations) { $0.pageIndex }
        var groups: [AnnotationGroup] = []
        
        for (pageIndex, notes) in byPage {
            // Sort by Y (top to bottom).
            let sortedInfo = notes.map { note -> (VoiceAnnotation, CGFloat) in
                let rect = NSCoder.cgRect(for: note.selectionBounds)
                return (note, rect.origin.y)
            }.sorted { $0.1 > $1.1 } 
            
            var currentCluster: [VoiceAnnotation] = []
            var lastY: CGFloat?
            
            for (note, y) in sortedInfo {
                if let last = lastY, abs(last - y) < 40 { // Cluster if within 40pts vertical
                    currentCluster.append(note)
                } else {
                    if !currentCluster.isEmpty {
                        groups.append(AnnotationGroup(annotations: currentCluster, pageIndex: pageIndex, avgY: 0))
                    }
                    currentCluster = [note]
                    lastY = y
                }
            }
            if !currentCluster.isEmpty {
                groups.append(AnnotationGroup(annotations: currentCluster, pageIndex: pageIndex, avgY: 0))
            }
        }
        return groups
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view, 
              let groupIdString = view.accessibilityValue,
              let uuid = UUID(uuidString: groupIdString),
              let group = activeGroups.first(where: { $0.id == uuid }) else { return }
        
        onBubbleTap?(group, view)
    }
    #endif
}
