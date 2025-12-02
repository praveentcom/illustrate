import AlertToast
import AVKit
import KeychainSwift
import PhotosUI
import SwiftData
import SwiftUI

struct VideoPreviewSheet: View {
    let videoURL: URL
    @Binding var isPresented: Bool
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            
            VideoPlayer(player: player)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding()
            }
        }
        .onAppear {
            player = AVPlayer(url: videoURL)
            player?.play()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
#if !os(macOS)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
#endif
    }
}

struct EditVideoView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var queueManager: QueueManager
    @Query(sort: \ConnectionKey.createdAt, order: .reverse) private var connectionKeys: [ConnectionKey]

    @StateObject private var viewModel = EditVideoViewModel()

    @FocusState private var focusedField: EditVideoViewModel.Field?

    var body: some View {
        VStack {
            if viewModel.hasConnection && !connectionKeys.isEmpty {
                Form {
                    Section(header: Text("Select Model")) {
                        Picker("Connection", selection: $viewModel.selectedConnectionId) {
                            ForEach(
                                viewModel.getSupportedConnections(connectionKeys: connectionKeys), id: \.connectionId
                            ) { connection in
                                HStack {
#if !os(macOS)
                                    Image("\(connection.connectionCode)_square".lowercased())
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
#endif
                                    Text(connection.connectionName)
                                }
                                .tag(connection.connectionId.uuidString)
                            }
                        }
#if !os(macOS)
                        .pickerStyle(.navigationLink)
#endif
                        .onChange(of: viewModel.selectedConnectionId) {
                            let models = viewModel.getSupportedModels(connectionKeys: connectionKeys)
                            viewModel.selectedModelId = models.first?.modelId.uuidString ?? ""
                        }

                        Picker("Model", selection: $viewModel.selectedModelId) {
                            ForEach(viewModel.getSupportedModels(connectionKeys: connectionKeys)) { model in
                                Text(model.modelName)
                                    .tag(model.modelId.uuidString)
                            }
                        }
#if !os(macOS)
                        .pickerStyle(.navigationLink)
#endif
                        .onChange(of: viewModel.selectedModelId) {
                            viewModel.validateAndSetDimensions()
                        }
                    }

                    Section("Video Settings") {
                        Picker("Dimensions", selection: $viewModel.artDimensions) {
                            ForEach(viewModel.getSelectedModel()?.modelSupportedParams.dimensions ?? [], id: \.self) { dimension in
                                Text(dimension)
                                    .tag(dimension)
                            }
                        }
#if !os(macOS)
                        .pickerStyle(.navigationLink)
#endif

                        Picker("Extension Duration", selection: $viewModel.durationSeconds) {
                            ForEach(viewModel.getAvailableDurations(), id: \.self) { duration in
                                Text("\(duration) seconds")
                                    .tag(duration)
                            }
                        }
#if !os(macOS)
                        .pickerStyle(.navigationLink)
#endif
                        
                        Toggle("Generate Audio", isOn: $viewModel.generateAudio)
                    }

                    Section(header: Text("Source Video")) {
                        if viewModel.isProcessingVideo {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Text("Processing video...")
                                Spacer()
                            }
                        } else if let thumbnail = viewModel.selectedVideoThumbnail {
#if os(macOS)
                            Image(nsImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .frame(maxHeight: 400)
                                .frame(maxWidth: .infinity)
                                .overlay(
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white.opacity(0.8))
                                )
                                .shadow(color: .black.opacity(0.3), radius: 6)
                                .padding(.vertical, 6)
                                .onTapGesture {
                                    viewModel.isVideoPreviewOpen = true
                                }
#else
                            Image(uiImage: thumbnail)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .frame(maxWidth: .infinity)
                                .overlay(
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white.opacity(0.8))
                                )
                                .padding(.vertical, 6)
                                .onTapGesture {
                                    viewModel.isVideoPreviewOpen = true
                                }
#endif
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "video.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("Select a video to extend")
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 150)
                            .frame(maxWidth: .infinity)
                            .onTapGesture {
                                viewModel.isVideoPickerOpen = true
                            }
                        }

                        HStack(spacing: 24) {
                            Spacer()
                            Button(viewModel.selectedVideoData != nil ? "Change video" : "Select video") {
                                viewModel.isVideoPickerOpen = true
                            }
                            if viewModel.selectedVideoData != nil {
                                Button("Remove", role: .destructive) {
                                    viewModel.clearVideo()
                                }
                            }
                            Spacer()
                        }
                    }

                    Section(header: Text("Extension Instructions")) {
                        TextField("Describe how to extend the video", text: $viewModel.prompt, prompt: Text("Eg. Continue with the camera panning right to reveal a mountain range..."), axis: .vertical)
                            .limitText($viewModel.prompt, to: viewModel.getSelectedModel()?.modelSupportedParams.maxPromptLength ?? 1024)
                            .lineLimit(3 ... 10)
                            .focused($focusedField, equals: .prompt)
                        
                        if viewModel.getSelectedModel()?.modelSupportedParams.negativePrompt ?? false {
                            TextField("Negative prompt (optional)", text: $viewModel.negativePrompt, prompt: Text("What to avoid..."), axis: .vertical)
                                .limitText($viewModel.negativePrompt, to: viewModel.getSelectedModel()?.modelSupportedParams.maxPromptLength ?? 1024)
                                .lineLimit(2 ... 6)
                                .focused($focusedField, equals: .negativePrompt)
                        }
                    }

                    Section {
                        EstimatedCostView(
                            cost: CostEstimator.estimatedVideoCost(
                                modelCode: viewModel.getSelectedModel()?.modelCode ?? .GOOGLE_VEO_31,
                                durationSeconds: viewModel.durationSeconds,
                                numberOfVideos: 1
                            ),
                            modelCode: viewModel.getSelectedModel()?.modelCode
                        )
                    }

                    Button("Extend Video") {
                        DispatchQueue.main.async {
                            focusedField = nil
                        }

                        viewModel.submitToQueue(connectionKeys: connectionKeys, queueManager: queueManager, modelContext: modelContext)
                    }
                    .disabled(!viewModel.canGenerate)
                }
                .formStyle(.grouped)
                .photosPicker(isPresented: $viewModel.isVideoPickerOpen, selection: $viewModel.selectedVideoItem, matching: .videos)
                .onChange(of: viewModel.selectedVideoItem) {
                    Task {
                        await viewModel.processSelectedVideo()
                    }
                }
                .sheet(isPresented: $viewModel.isVideoPreviewOpen) {
                    if let videoURL = viewModel.selectedVideoURL {
                        VideoPreviewSheet(videoURL: videoURL, isPresented: $viewModel.isVideoPreviewOpen)
                    }
                }

            } else {
                PendingConnectionView(setType: .VIDEO_VIDEO)
            }
        }
        .onAppear {
            viewModel.initialize(connectionKeys: connectionKeys)
        }
#if os(macOS)
        .toast(isPresenting: $viewModel.errorState.isShowing, duration: 12, offsetY: 16) {
            AlertToast(
                displayMode: .hud,
                type: .systemImage("exclamationmark.triangle", Color.red),
                title: viewModel.errorState.message,
                subTitle: "Tap to dismiss"
            )
        }
        .toast(isPresenting: $viewModel.showQueuedToast, duration: 3, offsetY: 16) {
            AlertToast(
                displayMode: .hud,
                type: .systemImage("checkmark.circle", Color.green),
                title: "Added to queue",
                subTitle: "Check the queue sidebar for progress"
            )
        }
#else
        .sheet(isPresented: $viewModel.errorState.isShowing) { [viewModel] in
            VStack(alignment: .center, spacing: 24) {
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .resizable()
                        .frame(width: 40, height: 40)
                    VStack(alignment: .center) {
                        Text(viewModel.errorState.message)
                            .multilineTextAlignment(.center)
                        Text("Dismiss to try again")
                            .multilineTextAlignment(.center)
                            .opacity(0.7)
                    }
                }
            }
            .padding(.all, 32)
        }
        .sheet(isPresented: $viewModel.showQueuedToast) {
            VStack(alignment: .center, spacing: 24) {
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.green)
                    VStack(alignment: .center) {
                        Text("Added to queue")
                            .multilineTextAlignment(.center)
                        Text("Check the queue for progress")
                            .multilineTextAlignment(.center)
                            .opacity(0.7)
                    }
                }
            }
            .padding(.all, 32)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    viewModel.showQueuedToast = false
                }
            }
        }
#endif
        .navigationDestination(isPresented: $viewModel.isNavigationActive) {
            if let _selectedSetId = viewModel.selectedSetId {
                GenerationVideoView(setId: _selectedSetId)
                    .onDisappear {
                        viewModel.resetNavigation()
                    }
            }
        }
        .navigationTitle(labelForItem(.generateVideoEdit))
    }
}

