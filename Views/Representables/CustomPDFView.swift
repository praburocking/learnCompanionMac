import PDFKit
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

protocol CustomPDFViewDelegate: AnyObject {
    func didRequestAddVoiceNote(selection: PDFSelection)
}

class CustomPDFView: PDFView {
    weak var customDelegate: CustomPDFViewDelegate?
    
#if os(iOS)
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(addVoiceNote(_:)) {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    @objc func addVoiceNote(_ sender: Any?) {
        guard let selection = currentSelection else { return }
        customDelegate?.didRequestAddVoiceNote(selection: selection)
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        #if os(iOS)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSelectionChange), name: .PDFViewSelectionChanged, object: self)
        #endif
    }
    
    // Force responder status for menu actions
    override var canBecomeFirstResponder: Bool { return true }
    
    @objc func handleSelectionChange() {
        guard let selection = currentSelection, let text = selection.string, !text.isEmpty else { return }
        
        // 1. Ensure we are part of the responder chain
        self.becomeFirstResponder()
        
        // 2. Force menu items
        let menuItem = UIMenuItem(title: "Record Notes", action: #selector(addVoiceNote(_:)))
        UIMenuController.shared.menuItems = [menuItem]
        
        // 3. Update menu (refresh if already visible)
        if UIMenuController.shared.isMenuVisible {
            UIMenuController.shared.update()
        } else {
            // Optional: Force show it (PDFView usually does this, but we can help)
            let bounds = selection.bounds(for: selection.pages[0])
            let rect = convert(bounds, from: selection.pages[0])
            UIMenuController.shared.showMenu(from: self, rect: rect)
        }
    }
    
    // Standard tap handling to bring back menu if selection exists
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        // Re-trigger selection logic to ensure menu persists
        handleSelectionChange()
    }
#endif
}
