import AlertToast
import KeychainSwift
import SwiftData
import SwiftUI

struct GenerateImageView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var queueManager: QueueManager
    @Query(sort: \ConnectionKey.createdAt, order: .reverse) private var connectionKeys: [ConnectionKey]

    @State private var selectedConnectionId: String = ""
    @State private var selectedModelId: String = ""

    func getSupportedModels() -> [ConnectionModel] {
        if selectedConnectionId == "" {
            return []
        }

        let service = ConnectionService.shared
        return service.allModels.filter {
            $0.modelSetType == EnumSetType.GENERATE &&
            $0.connectionId.uuidString == selectedConnectionId &&
            $0.active
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
            artVariant: artVariant,
            artQuality: artQuality,
            artStyle: artStyle,
            artDimensions: artDimensions,
            connectionKey: connectionKey,
            connectionSecret: connectionSecret,
            numberOfImages: numberOfImages
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
                                        ConnectionService.shared.allModels.contains { $0.connectionId == connection.connectionId && $0.modelSetType == .GENERATE && $0.active }
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
                        .onChange(of: selectedConnectionId) { _, _ in
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
                        .onChange(of: selectedModelId) { _, _ in
                            let supportedDimensions = getSelectedModel()?.modelSupportedParams.dimensions ?? []

                            if artDimensions == "" {
                                artDimensions = supportedDimensions.first ?? ""
                            } else if !supportedDimensions.contains(artDimensions) {
                                artDimensions = supportedDimensions.first ?? ""
                            }
                        }
                    }

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

                    if getSelectedModel()?.modelSupportedParams.prompt ?? false {
                        Section(header: Text("What do you want to generate?")) {
                            TextField("Describe your image", text: $prompt, prompt: Text("Eg. Landscape view of a city"), axis: .vertical)
                                .limitText($prompt, to: getSelectedModel()?.modelSupportedParams.maxPromptLength ?? 1)
                                .lineLimit(2 ... 8)
                                .focused($focusedField, equals: .prompt)
                            if getSelectedModel()?.modelSupportedParams.negativePrompt ?? false {
                                TextField("Negative prompt (if any)", text: $negativePrompt, prompt: Text("Eg. Without any clouds"), axis: .vertical)
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
                                modelCode: getSelectedModel()?.modelCode ?? .OPENAI_DALLE3,
                                quality: artQuality,
                                dimensions: artDimensions,
                                numberOfImages: numberOfImages
                            ),
                            modelCode: getSelectedModel()?.modelCode
                        )
                    }

                    Button("Generate") {
                        DispatchQueue.main.async {
                            focusedField = nil
                        }

                        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            DispatchQueue.main.async {
                                errorState = ErrorState(
                                    message: "Prompt is required to generate an image",
                                    isShowing: true
                                )
                            }
                            return
                        }

                        submitToQueue()
                    }
                    .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .formStyle(.grouped)
            } else {
                PendingConnectionView(setType: .GENERATE)
            }
        }
        .onAppear {
            if !connectionKeys.isEmpty && selectedModelId.isEmpty {
                let supportedConnections = connections.filter { connection in
                    connectionKeys.contains { $0.connectionId == connection.connectionId } &&
                        ConnectionService.shared.allModels.contains { $0.connectionId == connection.connectionId && $0.modelSetType == .GENERATE && $0.active }
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
                .navigationTitle(labelForItem(.generateGenerate))
    }
}
