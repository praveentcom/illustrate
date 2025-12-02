import AlertToast
import KeychainSwift
import PhotosUI
import SwiftData
import SwiftUI

struct ImageToVideoView: View {
    // MARK: Dependencies
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ConnectionKey.createdAt, order: .reverse) private var connectionKeys: [ConnectionKey]

    @StateObject private var viewModel: ImageToVideoViewModel

    // MARK: Initialization
    init() {
        _viewModel = StateObject(wrappedValue: ImageToVideoViewModel(modelContext: nil))
    }

    // MARK: Focus State
    @FocusState private var focusedField: ImageToVideoViewModel.Field?

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
                    .disabled(viewModel.isGenerating)

                    Section("Art Details") {
                        Picker("Dimensions", selection: $viewModel.artDimensions) {
                            ForEach(viewModel.getSelectedModel()?.modelSupportedParams.dimensions ?? [], id: \.self) { dimension in
                                HStack {
#if !os(macOS)
                                    Image("symbol_dimension_\(getAspectRatio(dimension: dimension).width)_\(getAspectRatio(dimension: dimension).height)")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
#endif
                                    Text(dimension)
                                }
                                .tag(dimension)
                            }
                        }
#if !os(macOS)
                        .pickerStyle(.navigationLink)
#endif
                        .onChange(of: viewModel.artDimensions) {
                            viewModel.updateDimensions(dimension: viewModel.artDimensions)
                        }

                        if viewModel.getSelectedModel()?.modelSupportedParams.quality ?? false {
                            Picker("Art Quality", selection: $viewModel.artQuality) {
                                ForEach(EnumArtQuality.allCases, id: \.self) { quality in
                                    HStack {
#if !os(macOS)
                                        Image("symbol_quality_\(quality.rawValue)".lowercased())
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
#endif
                                        Text(quality.rawValue)
                                            .monospaced()
                                    }
                                    .tag(quality)
                                }
                            }
#if !os(macOS)
                            .pickerStyle(.navigationLink)
#endif
                        }

                        if viewModel.getSelectedModel()?.modelSupportedParams.variant ?? false {
                            Picker("Art Variant", selection: $viewModel.artVariant) {
                                ForEach(EnumArtVariant.allCases, id: \.self) { variant in
                                    Text(variant.rawValue).tag(variant)
                                }
                            }
#if !os(macOS)
                            .pickerStyle(.navigationLink)
#endif
                        }

                        if viewModel.getSelectedModel()?.modelSupportedParams.style ?? false {
                            Picker("Color Style", selection: $viewModel.artStyle) {
                                ForEach(EnumArtStyle.allCases, id: \.self) { style in
                                    HStack {
#if !os(macOS)
                                        Image("symbol_color_\(style.rawValue)".lowercased())
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
#endif
                                        Text(style.rawValue)
                                    }
                                    .tag(style)
                                }
                            }
#if !os(macOS)
                            .pickerStyle(.navigationLink)
#endif
                        }
                    }
                    .disabled(viewModel.isGenerating)

                    Section {
                        ZStack {
                            SmoothAnimatedGradientView(colors: viewModel.colorPalette.compactMap { hex in
                                Color(getUniversalColorFromHex(hexString: hex))
                            })

                            if viewModel.selectedImage != nil {
#if os(macOS)
                                Image(nsImage: viewModel.selectedImage!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .frame(maxHeight: 400)
                                    .shadow(color: .black.opacity(0.4), radius: 8)
                                    .padding(.vertical, 6)
                                    .frame(maxWidth: .infinity)
#else
                                Image(uiImage: viewModel.selectedImage!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .padding(.vertical, 6)
#endif
                            } else {
                                Image("placeholder_select_image")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .frame(height: 200)
                                    .onTapGesture {
                                        viewModel.isPhotoPickerOpen = true
                                    }
                            }
                        }

                        HStack(spacing: 24) {
                            Spacer()
                            Button(viewModel.selectedImage != nil ? "Change image" : "Select image") {
                                viewModel.isPhotoPickerOpen = true
                            }
                            Spacer()
                        }
                    }

                    if viewModel.getSelectedModel()?.modelSupportedParams.prompt ?? false {
                        Section(header: Text("Generate instructions")) {
                            TextField("What's your video about?", text: $viewModel.prompt, prompt: Text("Eg. Cat flying over the clouds"), axis: .vertical)
                                .limitText($viewModel.prompt, to: viewModel.getSelectedModel()?.modelSupportedParams.maxPromptLength ?? 1)
                                .lineLimit(2 ... 8)
                                .focused($focusedField, equals: .prompt)
                            if viewModel.getSelectedModel()?.modelSupportedParams.negativePrompt ?? false {
                                TextField("Negative prompt (if any)", text: $viewModel.negativePrompt, prompt: Text("Enter negative prompt here"), axis: .vertical)
                                    .limitText($viewModel.negativePrompt, to: viewModel.getSelectedModel()?.modelSupportedParams.maxPromptLength ?? 1)
                                    .lineLimit(2 ... 8)
                                    .focused($focusedField, equals: .negativePrompt)
                            }
                        }
                        .disabled(viewModel.isGenerating)
                    }

                    Section("Video Preferences") {
                        VStack {
#if os(iOS)
                            Text("Motion: \(Int(viewModel.motion / 255 * 100))% (\(Int(viewModel.motion)))")
#endif
                            Slider(value: $viewModel.motion, in: 15 ... 255, step: 15) {
                                Text("Motion: \(Int(viewModel.motion / 255 * 100))% (\(Int(viewModel.motion)))")
                            }
                        }
                        VStack {
#if os(iOS)
                            Text("Stickyness: \(Int(viewModel.stickyness * 10))% \(viewModel.stickyness, specifier: "%.1f")")
#endif
                            Slider(value: $viewModel.stickyness, in: 0 ... 10, step: 0.5) {
                                Text("Stickyness: \(Int(viewModel.stickyness * 10))% \(viewModel.stickyness, specifier: "%.1f")")
                            }
                        }
                    }
                    .disabled(viewModel.isGenerating)

                    Section(header: Text("Additional requests")) {
                        if viewModel.getSelectedModel()?.modelSupportedParams.count ?? 1 > 1 {
                            Picker("Number of videos", selection: $viewModel.numberOfVideos) {
                                ForEach(1 ... (viewModel.getSelectedModel()?.modelSupportedParams.count ?? 1), id: \.self) { count in
                                    Text("\(count)")
                                        .tag(count)
                                }
                            }
#if !os(macOS)
                            .pickerStyle(.navigationLink)
#endif
                        }

                        if (viewModel.getSelectedModel()?.modelSupportedParams.autoEnhance ?? false) && ConnectionService.shared.isOpenAIConnected(connectionKeys: connectionKeys) {
                            HStack {
                                Toggle("Auto-enhance prompt?", isOn: $viewModel.promptEnhanceOpted)

                                Image(systemName: "info.circle")
                                    .foregroundColor(.secondary)
                                    .help(Text("Uses OpenAI to enhance your prompt for better results"))
                            }
                        }
                    }

                    Button(
                        viewModel.isGenerating ? "Generating, please wait..." : "Generate Video"
                    ) {
                        DispatchQueue.main.async {
                            focusedField = nil
                        }

                        Task {
                            let response = await viewModel.generateVideo(connectionKeys: connectionKeys)
                            viewModel.handleGenerationResponse(response: response)
                        }
                    }
                    .disabled(!viewModel.canGenerate)
                }
                .formStyle(.grouped)
                .photosPicker(isPresented: $viewModel.isPhotoPickerOpen, selection: $viewModel.selectedImageItem, matching: .all(of: [
                    .not(.videos),
                ]))
                .onChange(of: viewModel.selectedImageItem) {
                    Task {
                        if let loaded = try? await viewModel.selectedImageItem?.loadTransferable(type: Data.self) {
                            viewModel.processSelectedImage(loaded: loaded)
                        } else {
                            viewModel.selectedImage = nil
                            viewModel.colorPalette = []
                        }
                    }
                }
                .sheet(isPresented: $viewModel.isCropSheetOpen) {
                    ImageCropAdapter(
                        image: viewModel.selectedImage!,
                        cropDimensions: viewModel.artDimensions,
                        onCropConfirm: { image in
                            viewModel.handleImageCropping(image: image)
                        },
                        onCropCancel: {
                            viewModel.cancelImageCropping()
                        }
                    )
                }

            } else {
                PendingConnectionView(setType: .VIDEO_IMAGE)
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
        .toast(isPresenting: $viewModel.isGenerating, offsetY: 16) {
            AlertToast(
                displayMode: .hud,
                type: .loading,
                title: "Generating video",
                subTitle: "This might take a while, hang on."
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
                            .opacity(0.6)
                    }
                }
            }
            .padding(.all, 32)
        }
        .sheet(isPresented: $viewModel.isGenerating) {
            VStack(alignment: .center, spacing: 24) {
                VStack(alignment: .center, spacing: 8) {
                    ProgressView()
                        .frame(width: 24, height: 24)
                    VStack(alignment: .center) {
                        Text("Generating video")
                            .multilineTextAlignment(.center)
                        Text("This might take a while, hang on.")
                            .multilineTextAlignment(.center)
                            .opacity(0.6)
                    }
                }
            }
            .padding(.all, 32)
            .interactiveDismissDisabled()
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
        .navigationTitle(labelForItem(.generateVideoImage))
    }
}