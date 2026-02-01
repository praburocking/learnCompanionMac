import SwiftUI
import PDFKit
import SwiftData

struct ReaderView: View {
    @Bindable var viewModel: ReaderViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedGroupWrapper: AnnotationGroupWrapper?
    @State private var popoverAnchor: CGRect = .zero
    @State private var floatingOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                if let document = viewModel.pdfDocument {
                    PDFReaderView(
                        document: document,
                        selection: $viewModel.currentSelection,
                        annotations: viewModel.annotations,
                        targetAnnotation: viewModel.targetAnnotation,
                        onTapAnnotationGroup: { group, globalRect in
                            // Convert Global -> Local
                            let localFrame = geo.frame(in: .global)
                            let localX = globalRect.minX - localFrame.minX
                            let localY = globalRect.minY - localFrame.minY
                            let rect = CGRect(x: localX, y: localY, width: globalRect.width, height: globalRect.height)
                            
                            self.popoverAnchor = rect
                            self.selectedGroupWrapper = AnnotationGroupWrapper(annotations: group)
                        },
                        onAddVoiceNote: { selection in
                            viewModel.prepareRecording(for: selection)
                            viewModel.startRecordingDirectly()
                        },
                        playingId: viewModel.playingAnnotationID
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    ContentUnavailableView("Could not load PDF", systemImage: "exclamationmark.triangle", description: Text("The file path might be invalid."))
                        .frame(maxWidth: .infinity)
                }
                
                // Draggable Floating Player
                if let wrapper = selectedGroupWrapper {
                    AnnotationPopover(viewModel: viewModel, annotations: wrapper.annotations, onClose: {
                        selectedGroupWrapper = nil
                    })
                        .frame(width: 320)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 10)
                        .offset(floatingOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    floatingOffset = CGSize(width: value.translation.width + lastOffset.width, height: value.translation.height + lastOffset.height)
                                }
                                .onEnded { value in
                                    lastOffset = floatingOffset
                                }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        // Allow taps to pass through the empty space
                        .allowsHitTesting(true) // The frame itself is hit testable? No, only content.
                }
                
                // Recording Pill (Replacement for Sidebar)
                if viewModel.isRecording {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "waveform.circle.fill")
                                .foregroundStyle(.red)
                                .symbolEffect(.pulse.byLayer)
                            Text(formatDuration(viewModel.recordingDuration))
                                .monospacedDigit()
                            
                            Button("Stop", action: {
                                viewModel.stopRecording()
                            })
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .shadow(radius: 5)
                        .padding(.bottom, 40) // Raised from bottom to avoid home indicator
                    }
                    .transition(.move(edge: .bottom))
                }
            }
        }
        .navigationTitle(viewModel.book.title)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct AnnotationGroupWrapper: Identifiable {
    let id = UUID()
    let annotations: [VoiceAnnotation]
}


