import QuickLookThumbnailing
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct PDFThumbnailView: View {
    let book: Book
    @State private var thumbnail: Image?
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.1)
            
            if let thumbnail {
                thumbnail
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .shadow(radius: 2)
            } else {
                Image(systemName: "doc.text.fill")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
            }
        }
        .cornerRadius(8)
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        guard thumbnail == nil else { return }
        
        Task {
            guard let url = resolveBookmark(data: book.urlData) else { return }
            
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            
            #if os(macOS)
            let size = CGSize(width: 200, height: 300)
            let scale = NSScreen.main?.backingScaleFactor ?? 1.0
            #else
            let size = CGSize(width: 200, height: 300)
            let scale = UIScreen.main.scale
            #endif
            
            let request = QLThumbnailGenerator.Request(
                fileAt: url,
                size: size,
                scale: scale,
                representationTypes: .thumbnail
            )
            
            do {
                let thumbnail = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
                #if os(macOS)
                let image = thumbnail.nsImage
                await MainActor.run {
                    self.thumbnail = Image(nsImage: image)
                }
                #else
                let image = thumbnail.uiImage
                await MainActor.run {
                    self.thumbnail = Image(uiImage: image)
                }
                #endif
            } catch {
                print("Thumbnail gen failed: \(error)")
            }
        }
    }
    
    private func resolveBookmark(data: Data) -> URL? {
        var isStale = false
        do {
            #if os(macOS)
            let options: URL.BookmarkResolutionOptions = .withSecurityScope
            #else
            let options: URL.BookmarkResolutionOptions = []
            #endif
            return try URL(resolvingBookmarkData: data, options: options, relativeTo: nil, bookmarkDataIsStale: &isStale)
        } catch {
            print("Thumbnail: Failed to resolve bookmark: \(error)")
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let fallback = documents?.appendingPathComponent(book.title)
            if let fallback, FileManager.default.fileExists(atPath: fallback.path) {
                return fallback
            }
            return nil
        }
    }
}
