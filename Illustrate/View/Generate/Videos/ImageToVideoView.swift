import AlertToast
import KeychainSwift
import PhotosUI
import SwiftData
import SwiftUI

struct ImageToVideoView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var queueManager: QueueManager
    @Query(sort: \ConnectionKey.createdAt, order: .reverse) private var connectionKeys: [ConnectionKey]

    @StateObject private var viewModel = ImageToVideoViewModel()

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

                    Section("Art Details") {
                        if viewModel.isVeoModel {
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
                                viewModel.updateDimensions(dimension: viewModel.artDimensions)
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
                        } else {
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

                    Section(header: Text("Starting Frame")) {
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
                    
                    if viewModel.supportsLastFrame {
                        Section(header: Text("Ending Frame (Optional)")) {
                            ZStack {
                                SmoothAnimatedGradientView(colors: viewModel.colorPalette.compactMap { hex in
                                    Color(getUniversalColorFromHex(hexString: hex))
                                })
                                
                                if viewModel.selectedLastFrame != nil {
#if os(macOS)
                                    Image(nsImage: viewModel.selectedLastFrame!)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .frame(maxHeight: 400)
                                        .shadow(color: .black.opacity(0.4), radius: 8)
                                        .padding(.vertical, 6)
                                        .frame(maxWidth: .infinity)
#else
                                    Image(uiImage: viewModel.selectedLastFrame!)
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
                                            if viewModel.selectedImage != nil {
                                                viewModel.isLastFramePickerOpen = true
                                            }
                                        }
                                        .opacity(viewModel.selectedImage == nil ? 0.5 : 1.0)
                                }
                            }

                            HStack(spacing: 24) {
                                Spacer()
                                Button(viewModel.selectedLastFrame != nil ? "Change ending frame" : "Add ending frame") {
                                    viewModel.isLastFramePickerOpen = true
                                }
                                .disabled(viewModel.selectedImage == nil)
                                if viewModel.selectedLastFrame != nil {
                                    Button("Remove", role: .destructive) {
                                        viewModel.selectedLastFrame = nil
                                    }
                                }
                                Spacer()
                            }
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
                    }

                    if !viewModel.isVeoModel {
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
                    }

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

                                InfoTooltip("Uses OpenAI to enhance your prompt for better results")
                            }
                        }
                    }

                    Section {
                        if viewModel.isVeoModel {
                            EstimatedCostView(
                                cost: CostEstimator.estimatedVideoCost(
                                    modelCode: viewModel.getSelectedModel()?.modelCode ?? .STABILITY_IMAGE_TO_VIDEO,
                                    durationSeconds: viewModel.durationSeconds,
                                    numberOfVideos: viewModel.numberOfVideos
                                ),
                                modelCode: viewModel.getSelectedModel()?.modelCode
                            )
                        } else {
                            EstimatedCostView(
                                cost: CostEstimator.estimatedVideoCost(
                                    modelCode: viewModel.getSelectedModel()?.modelCode ?? .STABILITY_IMAGE_TO_VIDEO,
                                    durationSeconds: 4,
                                    numberOfVideos: viewModel.numberOfVideos
                                ),
                                modelCode: viewModel.getSelectedModel()?.modelCode
                            )
                        }
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
                .photosPicker(isPresented: $viewModel.isLastFramePickerOpen, selection: $viewModel.selectedLastFrameItem, matching: .images)
                .onChange(of: viewModel.selectedLastFrameItem) {
                    Task {
                        if let loaded = try? await viewModel.selectedLastFrameItem?.loadTransferable(type: Data.self) {
                            viewModel.processSelectedLastFrame(loaded: loaded)
                        } else {
                            viewModel.selectedLastFrame = nil
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
                .sheet(isPresented: $viewModel.isLastFrameCropSheetOpen) {
                    ImageCropAdapter(
                        image: viewModel.selectedLastFrame!,
                        cropDimensions: viewModel.artDimensions,
                        onCropConfirm: { image in
                            viewModel.handleLastFrameCropping(image: image)
                        },
                        onCropCancel: {
                            viewModel.cancelLastFrameCropping()
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
        .navigationTitle(labelForItem(.generateVideoImage))
    }
}
