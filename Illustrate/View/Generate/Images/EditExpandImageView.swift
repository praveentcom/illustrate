import AlertToast
import KeychainSwift
import PhotosUI
import SwiftData
import SwiftUI

struct EditExpandImageView: View {
    // MARK: Model Context
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ConnectionKey.createdAt, order: .reverse) private var connectionKeys: [ConnectionKey]
    
    @State private var selectedConnectionId: String = ""
    @State private var selectedModelId: String = ""
    
    func getSupportedModels() -> [ConnectionModel] {
        if selectedConnectionId == "" {
            return []
        }
        
        return ConnectionService.shared.models(for: EnumSetType.EDIT_EXPAND).filter {
            $0.connectionId.uuidString == selectedConnectionId
        }
    }
    
    func getSelectedModel() -> ConnectionModel? {
        return ConnectionService.shared.model(by: selectedModelId)
    }
    
    // MARK: Form States
    
    private enum Field: Int, CaseIterable {
        case prompt, negativePrompt
    }
    
    @FocusState private var focusedField: Field?
    
    @State private var prompt: String = ""
    @State private var negativePrompt: String = ""
    
    @State private var artDimensions: String = ""
    @State private var artQuality: EnumArtQuality = .HD
    @State private var artStyle: EnumArtStyle = .VIVID
    @State private var artVariant: EnumArtVariant = .NORMAL
    @State private var numberOfImages: Int = 1
    @State private var promptEnhanceOpted: Bool = false
    
    // MARK: Photo States
    
    @State private var isPhotoPickerOpen: Bool = false
    
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var selectedImage: PlatformImage?
    @State private var colorPalette: [String] = []
    
    @State private var isCropSheetOpen: Bool = false
    
    @State private var expandLeft: Bool = true
    @State private var expandRight: Bool = true
    @State private var expandTop: Bool = true
    @State private var expandBottom: Bool = true
    
    // MARK: Generation States
    
    @State private var isGenerating: Bool = false
    @State private var errorState = ErrorState(message: "", isShowing: false)
    func generateImage() async -> ImageSetResponse? {
        if !isGenerating {
            let keychain = KeychainSwift()
            keychain.accessGroup = keychainAccessGroup
            keychain.synchronizable = true
            
            let connectionSecret: String? = keychain.get(getSelectedModel()!.connectionId.uuidString)
            if connectionSecret == nil {
                isGenerating = false
                return ImageSetResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateImageAdapterErrorCode.ADAPTER_ERROR,
                    errorMessage: "Keychain record not found"
                )
            }
            
            isGenerating = true
            
            let adapter = GenerateImageAdapter(
                imageGenerationRequest: ImageGenerationRequest(
                    modelId: getSelectedModel()!.modelId.uuidString,
                    prompt: prompt,
                    negativePrompt: negativePrompt,
                    artDimensions: artDimensions,
                    clientImage: selectedImage?.toBase64PNG(),
                    connectionKey: connectionKeys.first(where: { $0.connectionId == getSelectedModel()!.connectionId })!,
                    connectionSecret: connectionSecret!,
                    editDirection: ImageEditDirection(
                        left: expandLeft ? 500 : 0,
                        right: expandRight ? 500 : 0,
                        up: expandTop ? 500 : 0,
                        down: expandBottom ? 500 : 0
                    )
                ),
                modelContext: modelContext
            )
            
            let response: ImageSetResponse = await adapter.makeRequest()
            
            isGenerating = false
#if !os(macOS)
            try? await Task.sleep(nanoseconds: 500_000_000)
#endif
            
            return response
        }
        
        return nil
    }
    
    // MARK: Navigation States
    
    @State private var isNavigationActive: Bool = false
    @State private var selectedSetId: UUID? = nil
    
    // MARK: View
    
    // MARK: Helper Functions
    
    var body: some View {
        VStack {
            if selectedModelId != "" && !connectionKeys.isEmpty {
                Form {
                    Section(header: Text("Select Model")) {
                        Picker("Connection", selection: $selectedConnectionId) {
                            ForEach(
                                connections.filter { connection in
                                    connectionKeys.contains { $0.connectionId == connection.connectionId } &&
                                    ConnectionService.shared.allModels.contains { $0.connectionId == connection.connectionId && $0.modelSetType == .EDIT_EXPAND }
                                }, id: \.connectionId
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
                        .onChange(of: selectedConnectionId) {
                            selectedModelId = getSupportedModels().first?.modelId.uuidString ?? ""
                        }
                        
                        Picker("Model", selection: $selectedModelId) {
                            ForEach(getSupportedModels()) { model in
                                Text(model.modelName)
                                    .tag(model.modelId.uuidString)
                            }
                        }
#if !os(macOS)
                        .pickerStyle(.navigationLink)
#endif
                        .onChange(of: selectedModelId) {
                            let supportedDimensions = getSelectedModel()?.modelSupportedParams.dimensions ?? []
                            
                            if artDimensions == "" {
                                artDimensions = supportedDimensions.first ?? ""
                                selectedImage = nil
                                colorPalette = []
                            } else if !supportedDimensions.contains(artDimensions) {
                                artDimensions = supportedDimensions.first ?? ""
                                selectedImage = nil
                                colorPalette = []
                            }
                        }
                    }
                    .disabled(isGenerating)
                    
                    Section(header: Text("Art Details")) {
                        Picker("Dimensions", selection: $artDimensions) {
                            ForEach(getSelectedModel()?.modelSupportedParams.dimensions ?? [], id: \.self) { dimension in
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
                        .onChange(of: artDimensions) {
                            selectedImage = nil
                            colorPalette = []
                        }
                        
                        if getSelectedModel()?.modelSupportedParams.quality ?? false {
                            Picker("Art Quality", selection: $artQuality) {
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
                        
                        if getSelectedModel()?.modelSupportedParams.variant ?? false {
                            Picker("Art Variant", selection: $artVariant) {
                                ForEach(EnumArtVariant.allCases, id: \.self) { variant in
                                    Text(variant.rawValue).tag(variant)
                                }
                            }
#if !os(macOS)
                            .pickerStyle(.navigationLink)
#endif
                        }
                        
                        if getSelectedModel()?.modelSupportedParams.style ?? false {
                            Picker("Color Style", selection: $artStyle) {
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
                    .disabled(isGenerating)
                    
                    Section {
                        ZStack {
                            SmoothAnimatedGradientView(colors: colorPalette.compactMap { hex in
                                Color(getUniversalColorFromHex(hexString: hex))
                            })
                            
                            if selectedImage != nil {
#if os(macOS)
                                Image(nsImage: selectedImage!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .padding(.leading, CGFloat(expandLeft ? 48 : 0))
                                    .padding(.trailing, CGFloat(expandRight ? 48 : 0))
                                    .padding(.top, CGFloat(expandTop ? 48 : 0))
                                    .padding(.bottom, CGFloat(expandBottom ? 48 : 0))
                                    .background(Color(NSColor.tertiarySystemFill))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .frame(maxHeight: 400)
                                    .shadow(color: .black.opacity(0.4), radius: 8)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
#else
                                Image(uiImage: selectedImage!)
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
                                        DispatchQueue.main.async {
                                            isPhotoPickerOpen = true
                                        }
                                    }
                            }
                        }
                        
#if os(macOS)
                        if selectedImage != nil {
                            VStack {
                                Text("Expand Directions")
                                HStack(spacing: 12) {
                                    Spacer()
                                    Toggle(isOn: $expandLeft) {
                                        Text("Left")
                                    }
                                    .toggleStyle(IllustrateToggleStyle())
                                    Toggle(isOn: $expandRight) {
                                        Text("Right")
                                    }
                                    .toggleStyle(IllustrateToggleStyle())
                                    Toggle(isOn: $expandTop) {
                                        Text("Top")
                                    }
                                    .toggleStyle(IllustrateToggleStyle())
                                    Toggle(isOn: $expandBottom) {
                                        Text("Bottom")
                                    }
                                    .toggleStyle(IllustrateToggleStyle())
                                    Spacer()
                                }
                            }
                        }
#endif
                        
                        HStack(spacing: 24) {
                            Spacer()
                            Button(selectedImage != nil ? "Change image" : "Select image") {
                                DispatchQueue.main.async {
                                    isPhotoPickerOpen = true
                                }
                            }
                            Spacer()
                        }
                    }
                    
                    if getSelectedModel()?.modelSupportedParams.prompt ?? false {
                        Section(header: Text("Expand instructions")) {
                            TextField("What should be the expanded view?", text: $prompt, prompt: Text("Eg. Enlarged landscape with more trees"), axis: .vertical)
                                .limitText($prompt, to: getSelectedModel()?.modelSupportedParams.maxPromptLength ?? 1)
                                .lineLimit(2 ... 8)
                                .focused($focusedField, equals: .prompt)
                            if getSelectedModel()?.modelSupportedParams.negativePrompt ?? false {
                                TextField("Negative prompt (if any)", text: $negativePrompt, prompt: Text("Enter negative prompt here"), axis: .vertical)
                                    .limitText($negativePrompt, to: getSelectedModel()?.modelSupportedParams.maxPromptLength ?? 1)
                                    .lineLimit(2 ... 8)
                                    .focused($focusedField, equals: .negativePrompt)
                            }
                        }
                        .disabled(isGenerating)
                    }
                    
                    Section(header: Text("Additional requests")) {
                        if getSelectedModel()?.modelSupportedParams.count ?? 1 > 1 {
                            Picker("Number of images", selection: $numberOfImages) {
                                ForEach(1 ... (getSelectedModel()?.modelSupportedParams.count ?? 1), id: \.self) { count in
                                    Text("\(count)")
                                        .tag(count)
                                }
                            }
#if !os(macOS)
                            .pickerStyle(.navigationLink)
#endif
                        }
                        
                        if (getSelectedModel()?.modelSupportedParams.autoEnhance ?? false) && ConnectionService.shared.isOpenAIConnected(connectionKeys: connectionKeys) {
                            HStack {
                                Toggle("Auto-enhance prompt?", isOn: $promptEnhanceOpted)
                                
                                Image(systemName: "info.circle")
                                    .foregroundColor(.secondary)
                                    .help(Text("Uses OpenAI to enhance your prompt for better results"))
                            }
                            
                        }
                    }
                    
                    Button(
                        isGenerating ? "Expanding, please wait..." : "Perform Expand"
                    ) {
                        DispatchQueue.main.async {
                            focusedField = nil
                        }
                        
                        Task {
                            let response = await generateImage()
                            if response?.status == EnumGenerationStatus.GENERATED && response?.set?.id != nil {
                                DispatchQueue.main.async {
                                    selectedSetId = response!.set!.id
                                    isNavigationActive = true
                                }
                            } else if response?.status == EnumGenerationStatus.FAILED {
                                DispatchQueue.main.async {
                                    errorState = ErrorState(
                                        message: response?.errorMessage ?? "Something went wrong",
                                        isShowing: true
                                    )
                                }
                            }
                        }
                    }
                    .disabled(isGenerating || selectedImage == nil)
                }
                .formStyle(.grouped)
                .photosPicker(isPresented: $isPhotoPickerOpen, selection: $selectedImageItem, matching: .all(of: [
                    .not(.videos),
                ]))
                .onChange(of: selectedImageItem) {
                    Task {
                        if let loaded = try? await selectedImageItem?.loadTransferable(type: Data.self) {
#if os(macOS)
                            selectedImage = NSImage(data: loaded)
#else
                            selectedImage = UIImage(data: loaded)
#endif
                            
                            if let selectedImage = selectedImage {
                                colorPalette = dominantColorsFromImage(selectedImage, clusterCount: 6)
                                isCropSheetOpen = true
                            }
                        } else {
                            selectedImage = nil
                            colorPalette = []
                        }
                    }
                }
                .sheet(isPresented: $isCropSheetOpen) {
                    ImageCropAdapter(
                        image: selectedImage!,
                        cropDimensions: artDimensions,
                        onCropConfirm: { image in
                            selectedImage = image
                            colorPalette = dominantColorsFromImage(selectedImage!, clusterCount: 6)
                            
                            isCropSheetOpen = false
                        },
                        onCropCancel: {
                            selectedImage = nil
                            colorPalette = []
                            
                            isCropSheetOpen = false
                        }
                    )
                }
            } else {
                PendingConnectionView(setType: .EDIT_EXPAND)
            }
        }
        .onAppear {
            if !connectionKeys.isEmpty && selectedModelId.isEmpty {
                let supportedConnections = connections.filter { connection in
                    connectionKeys.contains { $0.connectionId == connection.connectionId } &&
                    ConnectionService.shared.allModels.contains { $0.connectionId == connection.connectionId && $0.modelSetType == .EDIT_EXPAND }
                }
                
                if let firstSupportedConnection = supportedConnections.first,
                   let key = connectionKeys.first(where: { $0.connectionId == firstSupportedConnection.connectionId })
                {
                    selectedConnectionId = key.connectionId.uuidString
                    selectedModelId = getSupportedModels().first?.modelId.uuidString ?? ""
                    
                    if !selectedConnectionId.isEmpty, !selectedModelId.isEmpty {
                        artDimensions = getSelectedModel()?.modelSupportedParams.dimensions.first ?? ""
                    }
                }
            }
        }
#if os(macOS)
        .toast(isPresenting: $errorState.isShowing, duration: 12, offsetY: 16) {
            AlertToast(
                displayMode: .hud,
                type: .systemImage("exclamationmark.triangle", Color.red),
                title: errorState.message,
                subTitle: "Tap to dismiss"
            )
        }
        .toast(isPresenting: $isGenerating, offsetY: 16) {
            AlertToast(
                displayMode: .hud,
                type: .loading,
                title: "Generating image",
                subTitle: "This might take a while, hang on."
            )
        }
#else
        .sheet(isPresented: $errorState.isShowing) { [errorState] in
            VStack(alignment: .center, spacing: 24) {
                VStack(alignment: .center, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .resizable()
                        .frame(width: 40, height: 40)
                    VStack(alignment: .center) {
                        Text(errorState.message)
                            .multilineTextAlignment(.center)
                        Text("Dismiss to try again")
                            .multilineTextAlignment(.center)
                            .opacity(0.6)
                    }
                }
            }
            .padding(.all, 32)
        }
        .sheet(isPresented: $isGenerating) {
            VStack(alignment: .center, spacing: 24) {
                VStack(alignment: .center, spacing: 8) {
                    ProgressView()
                        .frame(width: 24, height: 24)
                    VStack(alignment: .center) {
                        Text("Generating image")
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
        .navigationDestination(isPresented: $isNavigationActive) {
            if let _selectedSetId = selectedSetId {
                GenerationImageView(setId: _selectedSetId)
                    .onDisappear {
                        DispatchQueue.main.async {
                            focusedField = nil
                            isNavigationActive = false
                            selectedSetId = nil
                        }
                    }
            }
        }
        .navigationTitle(labelForItem(.generateEditExpand))
    }
}
