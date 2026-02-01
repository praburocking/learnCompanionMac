import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.createdAt, order: .reverse) private var allBooks: [Book]
    @Query(sort: \BookCollection.createdAt, order: .reverse) private var collections: [BookCollection]
    
    @State private var collectionToRename: BookCollection?
    @State private var renameText: String = ""
    @State private var showRenameAlert = false
    @State private var showingImporter = false
    @State private var showAddCollectionAlert = false
    @State private var newCollectionName = ""
    
    private var gridLayout: [GridItem] {
        #if os(macOS)
        // macOS: Standard adaptive behavior for resizing windows
        return [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 20)]
        #else
        // iOS/iPad: Optimize for touch targets and screen width
        // Reduced to 150 to ensure at least 3 columns on standard Portrait (768/150 ≈ 5)
        // and avoid single-column fallback.
        return [GridItem(.adaptive(minimum: 150), spacing: 20)]
        #endif
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                // Combined Grid
                LazyVGrid(columns: gridLayout, spacing: 15) {
                    
                    // 1. Collections
                    ForEach(collections) { collection in
                        NavigationLink(destination: CollectionDetailView(collection: collection)) {
                            CollectionCardView(collection: collection)
                                .aspectRatio(2/3, contentMode: .fit) // Keep same aspect ratio as books for grid uniformity
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Rename") {
                                collectionToRename = collection
                                renameText = collection.name
                                showRenameAlert = true
                            }
                            Button(role: .destructive) {
                                deleteCollection(collection)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .dropDestination(for: String.self) { items, location in
                            // Accept book UUIDs dropped here
                            return handleDrop(items: items, onto: collection)
                        }
                    }
                    
                    // 2. Ungrouped Books
                    ForEach(allBooks.filter { $0.collection == nil }) { book in
                        NavigationLink(destination: BookReaderWrapper(book: book)) {
                            VStack {
                                PDFThumbnailView(book: book)
                                    .aspectRatio(2/3, contentMode: .fit)
                                    .frame(maxWidth: .infinity)
                                
                                Text(book.title)
                                    .font(.headline)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.primary)
                                
                                Text(book.createdAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .contextMenu {
                                Button(role: .destructive) {
                                    removeAllVoiceNotes(for: book)
                                } label: {
                                    Label("Remove all voice notes", systemImage: "waveform.slash")
                                }

                                Button(role: .destructive) {
                                    deleteBook(book)
                                } label: {
                                    Label("Delete file", systemImage: "trash")
                                }
                            }
                            .draggable(book.id.uuidString)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Library")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                     NavigationLink(destination: AllNotesView()) {
                        Label("All Notes", systemImage: "list.bullet.rectangle.portrait")
                    }
                }
#else
                ToolbarItem(placement: .navigation) {
                     NavigationLink(destination: AllNotesView()) {
                        Label("All Notes", systemImage: "list.bullet.rectangle.portrait")
                    }
                }
#endif
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: {
                            newCollectionName = ""
                            showAddCollectionAlert = true
                        }) {
                            Label("Add Collection", systemImage: "folder.badge.plus")
                        }
                        Button(action: { showingImporter = true }) {
                            Label("Add File (PDF)", systemImage: "doc.badge.plus")
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importPDF(url: url)
                case .failure(let error):
                    print("Import failed: \(error)")
                }
            }
            .alert("Rename Collection", isPresented: $showRenameAlert) {
                TextField("Collection Name", text: $renameText)
                Button("Rename") {
                    if let collection = collectionToRename {
                        collection.name = renameText
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("New Collection", isPresented: $showAddCollectionAlert) {
                TextField("Collection Name", text: $newCollectionName)
                Button("Create") {
                    if !newCollectionName.trimmingCharacters(in: .whitespaces).isEmpty {
                        addCollection(name: newCollectionName)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter a name for your new collection.")
            }
        }
    }
    
    private func addCollection(name: String) {
        let newCollection = BookCollection(name: name)
        modelContext.insert(newCollection)
    }
    
    private func deleteCollection(_ collection: BookCollection) {
         // If we delete collection, books inside are auto-deleted due to cascade rule?
         // User might expect ungrouping.
         // Let's ungroup first to be safe, or just allow deletion.
         // Requirement says "Relationship(deleteRule: .cascade)", so they will be deleted.
         // If we want to keep them, we should set their collection to nil first.
         // Let's just delete for now as per "Delete" semantics.
         withAnimation {
             modelContext.delete(collection)
         }
    }
    
    private func handleDrop(items: [String], onto collection: BookCollection) -> Bool {
        guard let uuidString = items.first, let uuid = UUID(uuidString: uuidString) else { return false }
        
        if let book = allBooks.first(where: { $0.id == uuid }) {
            withAnimation {
                book.collection = collection
            }
            return true
        }
        return false
    }
    
    private func importPDF(url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let savedURL = try FileService.shared.savePDF(from: url)
            // Create bookmark for the saved file in Documents (persisted access)
            let bookmarkData = try savedURL.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            
            let newBook = Book(title: url.lastPathComponent, urlData: bookmarkData)
            modelContext.insert(newBook)
        } catch {
            print("Failed to import PDF: \(error)")
        }
    }
    
    private func deleteBook(_ book: Book) {
        removeAllVoiceNotes(for: book)
        withAnimation {
            modelContext.delete(book)
        }
    }
    
    private func removeAllVoiceNotes(for book: Book) {
        let service = VoiceNoteService(modelContext: modelContext)
        let annotations = service.fetchAnnotations(for: book.title)
        for note in annotations {
            FileService.shared.deleteAudioFile(filename: note.audioFilePath)
            modelContext.delete(note)
        }
    }


}

struct BookReaderWrapper: View {
    let book: Book
    var targetAnnotationID: UUID? = nil
    
    @Environment(\.modelContext) var modelContext
    @State private var viewModel: ReaderViewModel?
    
    var body: some View {
        Group {
            if let vm = viewModel {
                ReaderView(viewModel: vm)
            } else {
                ContentUnavailableView("Loading...", systemImage: "doc.text")
            }
        }
        .onAppear {
            if viewModel == nil || viewModel?.book.id != book.id {
                let vm = ReaderViewModel(book: book, modelContext: modelContext)
                self.viewModel = vm
            }
            
            // Handle Navigation
            if let targetID = targetAnnotationID, let vm = viewModel {
                vm.playVoiceNote(id: targetID)
                // Also scroll to it? playVoiceNote plays it, but selectAnnotation scrolls.
                if let note = vm.annotations.first(where: { $0.id == targetID }) {
                     vm.selectAnnotation(note)
                }
            }
    }
}
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Book.self, BookCollection.self, configurations: config)
    
    // Add sample data
    let book1 = Book(title: "Sample PDF 1", urlData: Data())
    let book2 = Book(title: "Sample PDF 2", urlData: Data())
    container.mainContext.insert(book1)
    container.mainContext.insert(book2)
    
    let collection = BookCollection(name: "My Collection")
    container.mainContext.insert(collection)
    
    return DashboardView()
        .modelContainer(container)
}
