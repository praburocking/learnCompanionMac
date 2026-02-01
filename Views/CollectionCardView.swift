import SwiftUI

struct CollectionCardView: View {
    let collection: BookCollection
    
    var body: some View {
        ZStack {
            // Folder look
            Color.blue.opacity(0.1)
            
            VStack {
                // Folder Icon or Preview
                ZStack {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue.opacity(0.3))
                    
                    if let firstBook = collection.books.first {
                        PDFThumbnailView(book: firstBook)
                            .frame(width: 50, height: 75)
                            .shadow(radius: 2)
                            .rotationEffect(.degrees(-5))
                            .offset(x: -5, y: 5)
                    }
                }
                .frame(height: 90)
                
                Spacer()
                
                Text(collection.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                
                Text("\(collection.books.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}
