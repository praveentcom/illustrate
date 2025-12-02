import AlertToast
import KeychainSwift
import PhotosUI
import SwiftData
import SwiftUI

struct EditExpandImageView: View {
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
    
    @State private var isPhotoPickerOpen: Bool = false
    
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var selectedImage: PlatformImage?
    @State private var colorPalette: [String] = []
    
    @State private var isCropSheetOpen: Bool = false
    
    @State private var expandLeft: Bool = true
    @State private var expandRight: Bool = true
    @State private var expandTop: Bool = true
    @State private var expandBottom: Bool = true
    
    @EnvironmentObject private var queueManager: QueueManager
    @State private var errorState = ErrorState(message: "", isShowing: false)
    @State private var showQueuedToast: Bool = false
    
    func submitToQueue() {
        guard let selectedModel = getSelectedModel() else {
            errorState = ErrorState(
                message: "No model selected",
                isShowing: true
            )
            return
        }
        
        let keychain = KeychainSwift()
        keychain.accessGroup = keychainAccessGroup
        keychain.synchronizable = true

        guard let connectionSecret = keychain.get(selectedModel.connectionId.uuidString) else {
            errorState = ErrorState(
                message: "Keychain record not found",
                isShowing: true
            )
            return
        }
        
        guard let connectionKey = connectionKeys.first(where: { $0.connectionId == selectedModel.connectionId }) else {
            errorState = ErrorState(
                message: "Connection key not found",
                isShowing: true
            )
            return
        }
        
        let request = ImageGenerationRequest(
            modelId: selectedModel.modelId.uuidString,
            prompt: prompt,
            negativePrompt: negativePrompt,
            artDimensions: artDimensions,
            clientImage: selectedImage?.toBase64PNG(),
            connectionKey: connectionKey,
            connectionSecret: connectionSecret,
            editDirection: ImageEditDirection(
                left: expandLeft ? 500 : 0,
                right: expandRight ? 500 : 0,
                up: expandTop ? 500 : 0,
                down: expandBottom ? 500 : 0
            )
        )
        
        _ = queueManager.submitImageGeneration(
            request: request,
            modelContext: modelContext
        )
        
        showQueuedToast = true
    }
    
    @State private var isNavigationActive: Bool = false
    @State private var selectedSetId: UUID? = nil
    
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
                                
                                InfoTooltip("Uses OpenAI to enhance your prompt for better results")
                            }
                            
                        }
                    }
                    
                    Section {
                        EstimatedCostView(
                            cost: CostEstimator.estimatedImageCost(
                                modelCode: getSelectedModel()?.modelCode ?? .STABILITY_OUTPAINT,
                                quality: artQuality,
                                dimensions: artDimensions,
                                numberOfImages: numberOfImages
                            ),
                            modelCode: getSelectedModel()?.modelCode
                        )
                    }

                    Button("Perform Expand") {
                        DispatchQueue.main.async {
                            focusedField = nil
                        }
                        
                        submitToQueue()
                    }
                    .disabled(selectedImage == nil)
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
        .toast(isPresenting: $showQueuedToast, duration: 3, offsetY: 16) {
            AlertToast(
                displayMode: .hud,
                type: .systemImage("checkmark.circle", Color.green),
                title: "Added to queue",
                subTitle: "Check the queue sidebar for progress"
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
                            .opacity(0.7)
                    }
                }
            }
            .padding(.all, 32)
        }
        .sheet(isPresented: $showQueuedToast) {
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
                    showQueuedToast = false
                }
            }
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
