import SwiftUI
import SwiftData
import KeychainSwift
import AlertToast

struct GenerateImageView: View {
    // MARK: Model Context
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ConnectionKey.createdAt, order: .reverse) private var connectionKeys: [ConnectionKey]
    
    @State private var selectedConnectionId: String = ""
    @State private var selectedModelId: String = ""
    
    func getSupportedModels() -> [ConnectionModel] {
        if (selectedConnectionId == "") {
            return [];
        }
        
        return connectionModels.filter({ $0.modelSetType == EnumSetType.GENERATE && $0.connectionId.uuidString == selectedConnectionId })
    }
    
    func getSelectedModel() -> ConnectionModel? {
        return connectionModels.first(where: { $0.modelId.uuidString == selectedModelId })
    }
    
    // MARK: Form States
    private enum Field: Int, CaseIterable {
        case prompt, negativePrompt
    }
    @FocusState private var focusedField: Field?
    
    @State private var prompt: String = ""
    @State private var negativePrompt: String = ""
    
    @State private var artDimensions: String = ""
    @State private var artQuality: EnumArtQuality = EnumArtQuality.HD
    @State private var artStyle: EnumArtStyle = EnumArtStyle.VIVID
    @State private var artVariant: EnumArtVariant = EnumArtVariant.NORMAL
    @State private var numberOfImages: Int = 1
    @State private var promptEnhanceOpted: Bool = false
    
    // MARK: Generation States
    @State private var isGenerating: Bool = false
    @State private var showErrorToast = false
    @State private var errorMessage = ""
    func generateImage() async -> ImageSetResponse? {
        if (!isGenerating) {
            isGenerating = true
            
            let keychain = KeychainSwift()
            keychain.accessGroup = keychainAccessGroup
            keychain.synchronizable = true
            
            let connectionSecret: String? = keychain.get(getSelectedModel()!.connectionId.uuidString)
            if (connectionSecret == nil) {
                isGenerating = false
                return nil
            }
            
            let adapter = GenerateImageAdapter(
                imageGenerationRequest: ImageGenerationRequest(
                    modelId: getSelectedModel()!.modelId.uuidString,
                    prompt: prompt,
                    negativePrompt: negativePrompt,
                    artVariant: artVariant,
                    artQuality: artQuality,
                    artStyle: artStyle,
                    artDimensions: artDimensions,
                    connectionKey: connectionKeys.first(where: { $0.connectionId == getSelectedModel()!.connectionId })!,
                    connectionSecret: connectionSecret!,
                    numberOfImages: numberOfImages
                ),
                modelContext: modelContext
            )
            
            let response: ImageSetResponse = await adapter.makeRequest()
            
            isGenerating = false
            return response;
        }
        
        return nil
    }
    
    // MARK: Navigation States
    @State private var isNavigationActive: Bool = false
    @State private var selectedSetId: UUID? = nil
    
    var body: some View {
        VStack {
            if (selectedModelId != "" && !connectionKeys.isEmpty) {
                Form {
                    Section(header: Text("Select Model")) {
                        Picker("Connection", selection: $selectedConnectionId) {
                            ForEach(
                                connections.filter { connection in
                                    connectionKeys.contains { $0.connectionId == connection.connectionId } &&
                                    connectionModels.contains { $0.connectionId == connection.connectionId && $0.modelSetType == .GENERATE }
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
                            
                            if (artDimensions == "") {
                                artDimensions = supportedDimensions.first ?? ""
                            } else if (!supportedDimensions.contains(artDimensions)) {
                                artDimensions = supportedDimensions.first ?? ""
                            }
                        }
                    }
                    .disabled(isGenerating)
                    
                    Section("Details") {
                        Picker("Art Dimensions", selection: $artDimensions) {
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
                        
                        if (getSelectedModel()?.modelSupportedParams.quality ?? false) {
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
                        
                        if (getSelectedModel()?.modelSupportedParams.variant ?? false) {
                            Picker("Art Variant", selection: $artVariant) {
                                ForEach(EnumArtVariant.allCases, id: \.self) { variant in
                                    Text(variant.rawValue).tag(variant)
                                }
                            }
#if !os(macOS)
                            .pickerStyle(.navigationLink)
#endif
                        }
                        
                        if (getSelectedModel()?.modelSupportedParams.style ?? false) {
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
                    
                    if (getSelectedModel()?.modelSupportedParams.prompt ?? false) {
                        Section(header: Text("What do you want to generate?")) {
                            TextField("Describe your image", text: $prompt, prompt: Text("Eg. Landscape view of a city"), axis: .vertical)
                                .limitText($prompt, to: getSelectedModel()?.modelSupportedParams.maxPromptLength ?? 1)
                                .lineLimit(2...8)
                                .focused($focusedField, equals: .prompt)
                            if (getSelectedModel()?.modelSupportedParams.negativePrompt ?? false) {
                                TextField("Negative prompt (if any)", text: $negativePrompt, prompt: Text("Eg. Without any clouds"), axis: .vertical)
                                    .limitText($negativePrompt, to: getSelectedModel()?.modelSupportedParams.maxPromptLength ?? 1)
                                    .lineLimit(2...8)
                                    .focused($focusedField, equals: .negativePrompt)
                            }
                        }
                        .disabled(isGenerating)
                    }
                    
                    Section(header: Text("Additional requests")) {
                        if (getSelectedModel()?.modelSupportedParams.count ?? 1 > 1) {
                            Picker("Number of images", selection: $numberOfImages) {
                                ForEach(1...(getSelectedModel()?.modelSupportedParams.count ?? 1), id: \.self) { count in
                                    Text("\(count)")
                                        .tag(count)
                                }
                            }
                            #if !os(macOS)
                            .pickerStyle(.navigationLink)
                            #endif
                        }
                        
                        if (getSelectedModel()?.modelSupportedParams.autoEnhance ?? false) {
                            Toggle("Auto-enhance prompt?", isOn: $promptEnhanceOpted)
                        }
                    }
                    .disabled(isGenerating)
                    
                    Button(
                        isGenerating ? "Generating, please wait..." : "Generate"
                    ) {
                        focusedField = nil
                        Task {
                            let response = await generateImage()
                            if (response?.status == EnumGenerationStatus.GENERATED && response?.set?.id != nil) {
                                selectedSetId = response!.set!.id
                                isNavigationActive = true
                            } else if (response?.status == EnumGenerationStatus.FAILED) {
                                errorMessage = response?.errorMessage ?? "Something went wrong"
                                showErrorToast = true
                            }
                        }
                    }
                    .disabled(isGenerating)
                }
                .formStyle(.grouped)
            } else {
                PendingConnectionView(setType: .GENERATE)
            }
        }
        .onAppear() {
            if !connectionKeys.isEmpty && selectedModelId.isEmpty {
                let supportedConnections = connections.filter { connection in
                    connectionKeys.contains { $0.connectionId == connection.connectionId } &&
                    connectionModels.contains { $0.connectionId == connection.connectionId && $0.modelSetType == .GENERATE }
                }

                if let firstSupportedConnection = supportedConnections.first,
                   let key = connectionKeys.first(where: { $0.connectionId == firstSupportedConnection.connectionId }) {
                    
                    selectedConnectionId = key.connectionId.uuidString
                    selectedModelId = getSupportedModels().first?.modelId.uuidString ?? ""
                    
                    if !selectedConnectionId.isEmpty, !selectedModelId.isEmpty {
                        artDimensions = getSelectedModel()?.modelSupportedParams.dimensions.first ?? ""
                    }
                }
            }
        }
        .toast(isPresenting: $showErrorToast, duration: 4, offsetY: 16) {
            AlertToast(
                displayMode: .hud,
                type: .systemImage("exclamationmark.triangle", Color.red),
                title: errorMessage,
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
        .navigationDestination(isPresented: $isNavigationActive) {
            if (selectedSetId != nil) {
                GenerationImageView(setId: selectedSetId!)
            }
        }
        .navigationTitle(labelForItem(.generateGenerate))
    }
}
