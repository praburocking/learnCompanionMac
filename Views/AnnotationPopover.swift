import SwiftUI

struct AnnotationPopover: View {
    @Bindable var viewModel: ReaderViewModel
    let annotations: [VoiceAnnotation] // Group of annotations for this bubble
    var onClose: (() -> Void)?
    
    @State private var selectedNoteID: UUID?
    @State private var showTagSheet = false
    
    // Derived state for the active note (if single or selected from list)
    private var activeNote: VoiceAnnotation? {
        if let id = selectedNoteID {
            return annotations.first(where: { $0.id == id })
        }
        return annotations.first // Default to first if single
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if annotations.count > 1 && selectedNoteID == nil {
                // List State
                listView
            } else {
                // Player State
                if let note = activeNote {
                    playerView(for: note)
                }
            }
        }
        .frame(width: 300)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 10)
    }
    
    // MARK: - List View
    private var listView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Voice Notes (\(annotations.count))")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 10)
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(annotations) { note in
                        Button(action: {
                            withAnimation {
                                selectedNoteID = note.id
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.circle")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading) {
                                    Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    
                                    // Placeholder duration (needs real metadata)
                                    Text("0:00") 
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }
                }
            }
            .frame(maxHeight: 200)
        }
    }
    
    // MARK: - Player View
    private func playerView(for note: VoiceAnnotation) -> some View {
        VStack(spacing: 12) {
            // Header: Title & Back (if multiple)
            HStack {
                if annotations.count > 1 {
                    Button(action: {
                        withAnimation {
                            selectedNoteID = nil
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.blue)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(role: .destructive, action: {
                    viewModel.deleteNote(note)
                    if annotations.count <= 1 {
                         onClose?()
                    } else {
                        selectedNoteID = nil
                    }
                }) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                
                // Close Button
                Button(action: {
                    onClose?()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                        .font(.title3)
                }
                .padding(.leading, 8)
            }
            
            // Player Controls
            HStack(spacing: 15) {
                Button(action: {
                    if viewModel.isNotePlaying(note) {
                        viewModel.pausePlayback()
                    } else if viewModel.isNotePaused(note) {
                         viewModel.resumePlayback()
                    } else {
                        viewModel.playNote(note)
                    }
                }) {
                    Image(systemName: viewModel.isNotePlaying(note) ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.blue)
                }
                
                VStack(spacing: 4) {
                    // Waveform / Progress
                    // Simplified progress bar for now
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.3))
                                .frame(height: 4)
                            
                            if viewModel.currentPlayingURL?.lastPathComponent == note.audioFilePath {
                                Capsule()
                                    .fill(Color.blue)
                                    .frame(width: geo.size.width * CGFloat(viewModel.playbackProgress), height: 4)
                            }
                        }
                    }
                    .frame(height: 4)
                    
                    HStack {
                        if viewModel.currentPlayingURL?.lastPathComponent == note.audioFilePath {
                             // let duration = viewModel.recordingDuration 
                             // ViewModel needs better playback state exposure (current time / total time).
                             // content of ViewModel shows 'recordingDuration' but not 'playbackDuration'.
                             // For now, use placeholders or basic progress.
                             Text(formattedTime(viewModel.playbackProgress * 100)) // Hacky placeholder
                                 .font(.caption2)
                                 .monospacedDigit()
                        } else {
                             Text("0:00")
                                 .font(.caption2)
                                 .monospacedDigit()
                        }
                        Spacer()
                    }
                }
            }
            
            // Tag Section
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            if let tags = note.tags, !tags.isEmpty {
                                ForEach(tags) { tag in
                                    Text(tag.name)
                                        .font(.system(size: 10, weight: .medium))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color(hex: tag.colorHex)?.opacity(0.2) ?? Color.gray.opacity(0.2))
                                        .foregroundColor(Color(hex: tag.colorHex) ?? .primary)
                                        .cornerRadius(4)
                                }
                            } else {
                                Text("No tags")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showTagSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding(.top, 4)
            .sheet(isPresented: $showTagSheet) {
                TagSelectionView(annotation: note)
            }
        }
        .padding()
    }
    
    private func formattedTime(_ seconds: Double) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}
