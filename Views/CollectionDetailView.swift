
import SwiftUI
import SwiftData

struct CollectionDetailView: View {
    @Bindable var collection: BookCollection
    @Environment(\.modelContext) private var modelContext
    
    @State private var showRenameAlert = false
    @State private var renameText = ""
    @State private var showingImporter = false
    @State private var showMoveFilesSheet = false
    
    // Sort books in collection? 
    // We can rely on collection.books being a standard array, or we can use a Query if we passed ID.
    // Passing the object is easier for now.
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 20)], spacing: 20) {
                ForEach(collection.books.sorted(by: { $0.createdAt > $1.createdAt })) { book in
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
                                removeFromCollection(book)
                            } label: {
                                Label("Remove from Collection", systemImage: "arrow.uturn.backward")
                            }
                            
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
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle($collection.name)
        .toolbar {
             ToolbarItem(placement: .topBarTrailing) {
                 Menu {
                     Button(action: { showingImporter = true }) {
                         Label("Add File (PDF)", systemImage: "doc.badge.plus")
                     }
                     Button(action: { showMoveFilesSheet = true }) {
                         Label("Move Files Here", systemImage: "arrow.right.doc.on.clipboard")
                     }
                     Button("Rename") {
                         showRenameAlert = true
                         renameText = collection.name
                     }
                 } label: {
                     Image(systemName: "ellipsis.circle")
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
                collection.name = renameText
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showMoveFilesSheet) {
            MoveFilesPicker(targetCollection: collection)
        }
    }
    
    private func removeFromCollection(_ book: Book) {
        withAnimation {
            book.collection = nil
        }
    }
    
    private func deleteBook(_ book: Book) {
        // also remove voice notes first to clean up files
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
    
    private func importPDF(url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let savedURL = try FileService.shared.savePDF(from: url)
            let bookmarkData = try savedURL.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            
            let newBook = Book(title: url.lastPathComponent, urlData: bookmarkData)
            newBook.collection = collection
            modelContext.insert(newBook)
        } catch {
            print("Failed to import PDF: \(error)")
        }
    }
}

struct MoveFilesPicker: View {
    let targetCollection: BookCollection
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Book.title) private var allBooks: [Book]
    
    // Books that are not currently in this collection
    var availableBooks: [Book] {
        allBooks.filter { $0.collection?.id != targetCollection.id }
    }
    
    @State private var selectedBookIDs = Set<UUID>()
    
    var body: some View {
        NavigationStack {
            List(availableBooks, id: \.id) { book in
                HStack {
                    VStack(alignment: .leading) {
                        Text(book.title)
                            .font(.headline)
                        if let existing = book.collection {
                            Text("In: \(existing.name)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Ungrouped")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    if selectedBookIDs.contains(book.id) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.gray)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedBookIDs.contains(book.id) {
                        selectedBookIDs.remove(book.id)
                    } else {
                        selectedBookIDs.insert(book.id)
                    }
                }
            }
            .navigationTitle("Move to \(targetCollection.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Move") {
                        moveSelectedFiles()
                        dismiss()
                    }
                    .disabled(selectedBookIDs.isEmpty)
                }
            }
            .overlay {
                if availableBooks.isEmpty {
                    ContentUnavailableView("No Files to Move", systemImage: "doc.on.doc", description: Text("All files are already in this collection."))
                }
            }
        }
    }
    
    private func moveSelectedFiles() {
        for book in allBooks where selectedBookIDs.contains(book.id) {
            book.collection = targetCollection
        }
    }
}
