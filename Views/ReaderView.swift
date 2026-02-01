import SwiftUI
import PDFKit
import SwiftData

struct ReaderView: View {
    @Bindable var viewModel: ReaderViewModel
    @Environment(\.dismiss) var dismiss
    @Query(sort: \Tag.name) private var allTags: [Tag]
    
    @State private var selectedGroupWrapper: AnnotationGroupWrapper?
    @State private var popoverAnchor: CGRect = .zero
    @State private var floatingOffset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    // Filter State
    @State private var showFilterSheet = false
    @State private var selectedTagIDs: Set<UUID> = []
    @State private var showUntagged = true
    @State private var hasInitializedFilter = false
    
    // Compute filtered annotations based on selection
    var filteredAnnotations: [VoiceAnnotation] {
        if !hasInitializedFilter { return viewModel.annotations }
        
        return viewModel.annotations.filter { note in
            if let tags = note.tags, !tags.isEmpty {
                return tags.contains { selectedTagIDs.contains($0.id) }
            } else {
                return showUntagged
            }
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .center) {
                
                // Content Layer
                ZStack(alignment: .topTrailing) {
                    if let document = viewModel.pdfDocument {
                        PDFReaderView(
                            document: document,
                            selection: $viewModel.currentSelection,
                            annotations: filteredAnnotations,
                            targetAnnotation: viewModel.targetAnnotation,
                            onTapAnnotationGroup: { group, globalRect in
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ContentUnavailableView("Could not load PDF", systemImage: "exclamationmark.triangle", description: Text("The file path might be invalid."))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                            .allowsHitTesting(true)
                    }
                    
                    // Filter FAB (Bottom Left)
                    VStack {
                        Spacer()
                        HStack {
                            Button(action: {
                                print("OPENING FILTER MODAL")
                                if !hasInitializedFilter { initializeFilter() }
                                withAnimation(.easeOut(duration: 0.2)) {
                                    showFilterSheet = true
                                }
                            }) {
                                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .blue)
                                    .font(.system(size: 50))
                                    .shadow(radius: 4)
                            }
                            .padding(.leading, 20)
                            .padding(.bottom, 20)
                            Spacer()
                        }
                    }
                    
                    // Recording Pill (Bottom Center)
                    if viewModel.isRecording {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "waveform.circle.fill")
                                    .foregroundStyle(.red)
                                    .symbolEffect(.pulse.byLayer)
                                Text(formatDuration(viewModel.recordingDuration))
                                    .monospacedDigit()
                                
                                Button("Stop", action: { viewModel.stopRecording() })
                                    .buttonStyle(.borderedProminent)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                            .padding(.bottom, 40)
                        }
                        .transition(.move(edge: .bottom))
                    }
                }
                
                // Modal Overlay Layer (ZIndex 100)
                if showFilterSheet {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.2)) { showFilterSheet = false }
                        }
                        .zIndex(99)
                    
                    FilterModalView(
                        allTags: allTags,
                        selectedTagIDs: $selectedTagIDs,
                        showUntagged: $showUntagged,
                        onClose: { withAnimation(.easeOut(duration: 0.2)) { showFilterSheet = false } },
                        onSelectAll: {
                            selectedTagIDs = Set(allTags.map(\.id))
                            showUntagged = true
                        }
                    )
                    .frame(width: 400, height: 550)
                    .transition(.opacity) // Pure opacity to avoid "drawer" look
                    .zIndex(100)
                }
            }
        }
        .navigationTitle(viewModel.book.title)
        .onAppear {
            if !hasInitializedFilter && !allTags.isEmpty { initializeFilter() }
        }
        .onChange(of: allTags) { oldValue, newTags in
            if !hasInitializedFilter && !newTags.isEmpty { initializeFilter() }
        }
    }
    
    private func initializeFilter() {
        selectedTagIDs = Set(allTags.map(\.id))
        showUntagged = true
        hasInitializedFilter = true
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Filter Modal View
struct FilterModalView: View {
    var allTags: [Tag]
    @Binding var selectedTagIDs: Set<UUID>
    @Binding var showUntagged: Bool
    var onClose: () -> Void
    var onSelectAll: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onClose) {
                    Text("Done").bold()
                }
                
                Spacer()
                
                Text("Filter Notes")
                    .font(.headline)
                
                Spacer()
                
                Button("Select All") { onSelectAll() }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            Divider()
            
            // Content
            List {
                Section {
                    Toggle(isOn: $showUntagged) {
                        Label("Show Untagged Notes", systemImage: "tag.slash")
                            .foregroundStyle(.primary)
                    }
                }
                
                Section(header: Text("Filter by Tag")) {
                    if allTags.isEmpty {
                        Text("No tags available")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(allTags) { tag in
                            Toggle(isOn: Binding(
                                get: { selectedTagIDs.contains(tag.id) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedTagIDs.insert(tag.id)
                                    } else {
                                        selectedTagIDs.remove(tag.id)
                                    }
                                }
                            )) {
                                HStack {
                                    Circle()
                                        .fill(Color(hex: tag.colorHex) ?? .gray)
                                        .frame(width: 12, height: 12)
                                    Text(tag.name)
                                        .font(.body)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .background(.thickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.3), radius: 25, x: 0, y: 15)
    }
}

struct AnnotationGroupWrapper: Identifiable {
    let id = UUID()
    let annotations: [VoiceAnnotation]
}
