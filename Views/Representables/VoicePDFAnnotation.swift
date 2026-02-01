import PDFKit
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

class VoicePDFAnnotation: PDFAnnotation {
    var voiceAnnotationID: UUID
    
    init(bounds: CGRect, id: UUID) {
        self.voiceAnnotationID = id
        super.init(bounds: bounds, forType: .highlight,withProperties: nil)
        self.color = .purple.withAlphaComponent(0.3)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        super.draw(with: box, in: context)
        
        // Draw a little mic icon in the top left corner of the bounds
        let iconSize: CGFloat = 16
        // Determine rect for icon relative to bounds.
        // Bounds are in PDF page coordinate system.
        
        // Simple circle for MVP
        context.saveGState()
        context.setFillColor(red: 0.5, green: 0, blue: 0.5, alpha: 1.0)
        let circleRect = CGRect(x: bounds.origin.x - iconSize/2, y: bounds.origin.y + bounds.height - iconSize/2, width: iconSize, height: iconSize)
        context.fillEllipse(in: circleRect)
        context.restoreGState()
    }
}
