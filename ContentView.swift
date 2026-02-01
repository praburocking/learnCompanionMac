import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.createdAt, order: .reverse) private var books: [Book]

    @State private var showingImporter = false
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(books) { book in
                    NavigationLink {
                        // Create ViewModel here
                        // In a real app, we might use a Factory or StateObject properly
                        ReaderView(viewModel: ReaderViewModel(book: book, modelContext: modelContext))
            } label: {
                Text(book.title)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Library")
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Button(action: { showingImporter = true }) {
                        Label("Add Item", systemImage: "plus")
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
        } detail: {
            Text("Select a book")
        }
    }

    private func importPDF(url: URL) {
        // Security scope for the source URL
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            // For persistence, we should copy the file to our container or create a security scoped bookmark.
            // Option A: Copy file (Easier for MVP)
            // Option B: Bookmark (Better for avoiding duplication, but requires staying valid)
            
            // Let's create a Bookmark of the *source* if we want to read in place, 
            // OR copy it. Since we are a reader, copying is safer so we own it.
            // But let's use FileService.savePDF
            
            let savedURL = try FileService.shared.savePDF(from: url)
            
            // Now create bookmark for the SAVED file so we can access it later securely?
            // Since it's in our Documents dir, we don't strictly need bookmark if we use relative paths,
            // but `Book.urlData` expects Data. Let's create a bookmark to the SAVED file.
            
            let bookmarkData = try savedURL.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            
            let newBook = Book(title: url.lastPathComponent, urlData: bookmarkData)
            modelContext.insert(newBook)
            
        } catch {
            print("Failed to import PDF: \(error)")
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(books[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Book.self, inMemory: true)
}
