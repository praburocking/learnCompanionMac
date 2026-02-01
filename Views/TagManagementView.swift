import SwiftUI
#if os(iOS)
import UIKit
#endif
import SwiftData

struct TagManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Tag.name) private var tags: [Tag]
    
    @State private var newTagName: String = ""
    @State private var selectedColorIndex = 7
    
    private let presetColors: [(color: Color, hex: String)] = [
        (.red, "#FF3B30"),
        (.orange, "#FF9500"),
        (.yellow, "#FFCC00"),
        (.green, "#34C759"),
        (.mint, "#00C7BE"),
        (.teal, "#30B0C7"),
        (.cyan, "#32ADE6"),
        (.blue, "#007AFF"),
        (.indigo, "#5856D6"),
        (.purple, "#AF52DE"),
        (.pink, "#FF2D55"),
        (.brown, "#A2845E")
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                // Add Tag Form
                VStack(spacing: 12) {
                    HStack {
                         TextField("New Tag Name", text: $newTagName)
                            .textFieldStyle(.roundedBorder)
                        
                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                        .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                   
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 30))], spacing: 8) {
                        ForEach(0..<presetColors.count, id: \.self) { index in
                            Circle()
                                .fill(presetColors[index].color)
                                .frame(width: 30, height: 30)
                                .overlay {
                                    if index == selectedColorIndex {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundColor(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedColorIndex = index
                                }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
                
                // Tag List
                List {
                    ForEach(tags) { tag in
                        HStack {
                            Circle()
                                .fill(Color(hex: tag.colorHex) ?? .gray)
                                .frame(width: 12, height: 12)
                            
                            Text(tag.name)
                                .font(.headline)
                            
                            Spacer()
                            
                            if let count = tag.annotations?.count, count > 0 {
                                Text("\(count) notes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteTags)
                }
            }
            .navigationTitle("Manage Tags")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addTag() {
        let name = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        let colorHex = presetColors[selectedColorIndex].hex
        let tag = Tag(name: name, colorHex: colorHex)
        modelContext.insert(tag)
        
        do {
            try modelContext.save()
            print("Tag saved: \(tag.name)")
        } catch {
            print("Error saving tag: \(error)")
        }
        
        newTagName = ""
        selectedColorIndex = 7
    }
    
    private func deleteTags(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(tags[index])
            }
            try? modelContext.save()
        }
    }
}

// Helper extensions for Color hex conversion
extension Color {
    func toHex() -> String? {
        #if os(macOS)
        let uic = NSColor(self)
        #else
        let uic = UIColor(self)
        #endif
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if a != Float(1.0) {
            return String(format: "#%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
    
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0
        
        let length = hexSanitized.count
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
            
        } else {
            return nil
        }
        
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}
