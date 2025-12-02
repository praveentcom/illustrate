import AlertToast
import KeychainSwift
import SwiftData
import SwiftUI

struct TextToVideoView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var queueManager: QueueManager
    @Query(sort: \ConnectionKey.createdAt, order: .reverse) private var connectionKeys: [ConnectionKey]

    @StateObject private var viewModel = TextToVideoViewModel()

    @FocusState private var focusedField: TextToVideoViewModel.Field?

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
                        .onChange(of: viewModel.artDimensions) {
                            if viewModel.is1080p && viewModel.durationSeconds != 8 {
                                viewModel.durationSeconds = 8
                            }
                        }

                        Picker("Duration", selection: $viewModel.durationSeconds) {
                            ForEach(viewModel.getAvailableDurations(), id: \.self) { duration in
                                Text("\(duration) seconds")
                                    .tag(duration)
                            }
                        }
#if !os(macOS)
                        .pickerStyle(.navigationLink)
#endif
                        
                        if viewModel.supportsAudio {
                            Toggle("Generate Audio", isOn: $viewModel.generateAudio)
                        }
                    }

                    Section(header: Text("Describe your video")) {
                        TextField("What's your video about?", text: $viewModel.prompt, prompt: Text("Eg. A cinematic shot of a golden retriever running through a meadow at sunset..."), axis: .vertical)
                            .limitText($viewModel.prompt, to: viewModel.getSelectedModel()?.modelSupportedParams.maxPromptLength ?? 1024)
                            .lineLimit(3 ... 10)
                            .focused($focusedField, equals: .prompt)
                        
                        if viewModel.getSelectedModel()?.modelSupportedParams.negativePrompt ?? false {
                            TextField("Negative prompt (optional)", text: $viewModel.negativePrompt, prompt: Text("What to avoid in the video..."), axis: .vertical)
                                .limitText($viewModel.negativePrompt, to: viewModel.getSelectedModel()?.modelSupportedParams.maxPromptLength ?? 1024)
                                .lineLimit(2 ... 6)
                                .focused($focusedField, equals: .negativePrompt)
                        }
                    }

                    Section {
                        EstimatedCostView(
                            cost: CostEstimator.estimatedVideoCost(
                                modelCode: viewModel.getSelectedModel()?.modelCode ?? .GOOGLE_VEO_2,
                                durationSeconds: viewModel.durationSeconds,
                                numberOfVideos: 1
                            ),
                            modelCode: viewModel.getSelectedModel()?.modelCode
                        )
                    }

                    Button("Generate Video") {
                        DispatchQueue.main.async {
                            focusedField = nil
                        }

                        viewModel.submitToQueue(connectionKeys: connectionKeys, queueManager: queueManager, modelContext: modelContext)
                    }
                    .disabled(!viewModel.canGenerate)
                }
                .formStyle(.grouped)

            } else {
                PendingConnectionView(setType: .VIDEO_TEXT)
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
        .navigationTitle(labelForItem(.generateVideoText))
    }
}
