import AlertToast
import KeychainSwift
import SwiftData
import SwiftUI

struct TextToVideoView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var queueManager: QueueManager
    @Query(sort: \ProviderKey.createdAt, order: .reverse) private var providerKeys: [ProviderKey]

    @StateObject private var viewModel = TextToVideoViewModel()

    @FocusState private var focusedField: TextToVideoViewModel.Field?

    var body: some View {
        VStack {
            if viewModel.hasProvider && !providerKeys.isEmpty {
                Form {
                    Section(header: Text("Select Model")) {
                        Picker("Provider", selection: $viewModel.selectedProviderId) {
                            ForEach(
                                viewModel.getSupportedProviders(providerKeys: providerKeys), id: \.providerId
                            ) { provider in
                                HStack {
#if !os(macOS)
                                    Image("\(provider.providerCode)_square".lowercased())
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
#endif
                                    Text(provider.providerName)
                                }
                                .tag(provider.providerId.uuidString)
                            }
                        }
#if !os(macOS)
                        .pickerStyle(.navigationLink)
#endif
                        .onChange(of: viewModel.selectedProviderId) {
                            let models = viewModel.getSupportedModels(providerKeys: providerKeys)
                            viewModel.selectedModelId = models.first?.modelId.uuidString ?? ""
                        }

                        Picker("Model", selection: $viewModel.selectedModelId) {
                            ForEach(viewModel.getSupportedModels(providerKeys: providerKeys)) { model in
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
                        Picker("Aspect Ratio", selection: $viewModel.artDimensions) {
                            ForEach(viewModel.getSelectedModel()?.modelSupportedParams.dimensions ?? [], id: \.self) { dimension in
                                Text(dimension)
                                    .tag(dimension)
                            }
                        }
#if !os(macOS)
                        .pickerStyle(.navigationLink)
#endif
                        
                        if viewModel.hasResolutionOptions {
                            Picker("Resolution", selection: $viewModel.selectedResolution) {
                                ForEach(viewModel.getSupportedResolutions(), id: \.self) { resolution in
                                    Text(resolution)
                                        .tag(resolution)
                                }
                            }
#if !os(macOS)
                            .pickerStyle(.navigationLink)
#endif
                        }
                        
                        if viewModel.hasFPSOptions {
                            Picker("Frame Rate", selection: $viewModel.selectedFPS) {
                                ForEach(viewModel.getSupportedFPS(), id: \.self) { fps in
                                    Text("\(fps) fps")
                                        .tag(fps)
                                }
                            }
#if !os(macOS)
                            .pickerStyle(.navigationLink)
#endif
                        }

                        VStack(alignment: .leading) {
                            Text("Duration: \(viewModel.durationSeconds) seconds")
                            Slider(
                                value: Binding(
                                    get: { Double(viewModel.durationSeconds) },
                                    set: { viewModel.durationSeconds = Int($0) }
                                ),
                                in: Double(viewModel.getSupportedDurations().first ?? 4)...Double(viewModel.getSupportedDurations().last ?? 8),
                                step: 1
                            )
                        }
                        
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

                        viewModel.submitToQueue(providerKeys: providerKeys, queueManager: queueManager, modelContext: modelContext)
                    }
                    .disabled(!viewModel.canGenerate)
                }
                .formStyle(.grouped)
#if !os(macOS)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
                        }
                    }
                }
#endif

            } else {
                PendingProviderView(setType: .VIDEO_TEXT)
            }
        }
        .onAppear {
            viewModel.initialize(providerKeys: providerKeys)
        }
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
                subTitle: "Check the queue pane for progress"
            )
        }
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
