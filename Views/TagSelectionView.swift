
import SwiftUI
import SwiftData

struct TagSelectionView: View {
    var annotation: VoiceAnnotation
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Tag.name) private var tags: [Tag]
    
    @State private var showingCreateTagSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                if tags.isEmpty {
                    ContentUnavailableView("No Tags", systemImage: "tag.slash", description: Text("No tags created yet."))
                }
                
                ForEach(tags) { tag in
                    HStack {
                        Circle()
                            .fill(Color(hex: tag.colorHex) ?? .gray)
                            .frame(width: 12, height: 12)
                        
                        Text(tag.name)
                        
                        Spacer()
                        
                        if annotation.tags?.contains(where: { $0.id == tag.id }) == true {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        toggleTag(tag)
                    }
                }
            }
            .navigationTitle("Select Tags")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleTag(_ tag: Tag) {
        if var currentTags = annotation.tags {
            if let index = currentTags.firstIndex(where: { $0.id == tag.id }) {
                currentTags.remove(at: index)
            } else {
                currentTags.append(tag)
            }
            annotation.tags = currentTags
        } else {
            annotation.tags = [tag]
        }
        try? modelContext.save()
    }
}
