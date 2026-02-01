
import SwiftUI
import SwiftData

enum GroupingMode: String, CaseIterable {
    case none = "All"
    case byFile = "By File"
    case byTag = "By Tag"
}

struct AllNotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VoiceAnnotation.createdAt, order: .reverse) private var annotations: [VoiceAnnotation]
    @Query private var books: [Book]
    @Query(sort: \Tag.name) private var allTags: [Tag]
    
    @State private var groupingMode: GroupingMode = .none
    
    var body: some View {
        List {
            switch groupingMode {
            case .none:
                flatList
            case .byFile:
                groupedByFile
            case .byTag:
                groupedByTag
            }
        }
        .navigationTitle("All Voice Notes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Group By", selection: $groupingMode) {
                        ForEach(GroupingMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                } label: {
                    Label("Group", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }
    
    // MARK: - Flat List (No Grouping)
    @ViewBuilder
    private var flatList: some View {
        ForEach(annotations) { note in
            noteRow(note)
        }
    }
    
    // MARK: - Grouped by File
    @ViewBuilder
    private var groupedByFile: some View {
        let grouped = Dictionary(grouping: annotations, by: { $0.pdfFileName })
        let sortedKeys = grouped.keys.sorted()
        
        ForEach(sortedKeys, id: \.self) { fileName in
            Section(header: Text(fileName)) {
                ForEach(grouped[fileName] ?? []) { note in
                    noteRow(note)
                }
            }
        }
    }
    
    // MARK: - Grouped by Tag
    @ViewBuilder
    private var groupedByTag: some View {
        // Notes with tags
        ForEach(allTags) { tag in
            let notesWithTag = annotations.filter { note in
                note.tags?.contains(where: { $0.id == tag.id }) == true
            }
            if !notesWithTag.isEmpty {
                Section(header: HStack {
                    Circle()
                        .fill(Color(hex: tag.colorHex) ?? .gray)
                        .frame(width: 10, height: 10)
                    Text(tag.name)
                }) {
                    ForEach(notesWithTag) { note in
                        noteRow(note)
                    }
                }
            }
        }
        
        // Notes without tags
        let untagged = annotations.filter { $0.tags?.isEmpty != false }
        if !untagged.isEmpty {
            Section(header: Text("Untagged")) {
                ForEach(untagged) { note in
                    noteRow(note)
                }
            }
        }
    }
    
    // MARK: - Note Row
    @ViewBuilder
    private func noteRow(_ note: VoiceAnnotation) -> some View {
        if let book = books.first(where: { $0.title == note.pdfFileName }) {
            NavigationLink(destination: BookReaderWrapper(book: book, targetAnnotationID: note.id)) {
                VStack(alignment: .leading, spacing: 5) {
                    if groupingMode != .byFile {
                        Text(book.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    if let snippet = note.textSnippet, !snippet.isEmpty {
                        Text("\"\(snippet)\"")
                            .font(.subheadline)
                            .italic()
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    } else {
                        Text("Voice Note (Page \(note.pageIndex + 1))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if groupingMode != .byTag, let tags = note.tags, !tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(tags) { tag in
                                    Text("#" + tag.name)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(hex: tag.colorHex) ?? .gray)
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
