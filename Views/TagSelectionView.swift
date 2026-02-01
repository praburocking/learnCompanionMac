
import SwiftUI
import SwiftData

struct TagSelectionView: View {
    var annotation: VoiceAnnotation
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Tag.name) private var tags: [Tag]
    
    @State private var newTagName = ""
    @State private var newTagColor = Color.blue
    @State private var isCreatingTag = false
    
    private let presetColors: [Color] = [
        .red, .orange, .yellow, .green, .mint,
        .teal, .cyan, .blue, .indigo, .purple, .pink, .brown
    ]
    
    var body: some View {
        NavigationStack {
            List {
                // Create New Tag Section
                Section {
                    if isCreatingTag {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Tag name", text: $newTagName)
                                .textFieldStyle(.roundedBorder)
                            
                            Text("Color")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 30))], spacing: 8) {
                                ForEach(presetColors, id: \.self) { color in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 30, height: 30)
                                        .overlay {
                                            if color == newTagColor {
                                                Image(systemName: "checkmark")
                                                    .font(.caption.bold())
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .onTapGesture {
                                            newTagColor = color
                                        }
                                }
                            }
                            
                            HStack {
                                Button("Cancel") {
                                    isCreatingTag = false
                                    newTagName = ""
                                }
                                .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Button("Create") {
                                    createTag()
                                }
                                .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Button(action: { isCreatingTag = true }) {
                            Label("Create New Tag", systemImage: "plus.circle.fill")
                        }
                    }
                }
                
                // Existing Tags Section
                Section(header: Text("Available Tags")) {
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
                    
                    if tags.isEmpty {
                        Text("No tags yet. Create one above!")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
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
    }
    
    private func createTag() {
        let name = newTagName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        
        let hexColor = newTagColor.toHex() ?? "#007AFF"
        let newTag = Tag(name: name, colorHex: hexColor)
        modelContext.insert(newTag)
        
        // Auto-assign to current annotation
        if var currentTags = annotation.tags {
            currentTags.append(newTag)
            annotation.tags = currentTags
        } else {
            annotation.tags = [newTag]
        }
        
        // Reset form
        newTagName = ""
        isCreatingTag = false
    }
}
