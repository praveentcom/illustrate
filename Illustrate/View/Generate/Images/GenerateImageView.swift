import SwiftUI
import SwiftData

struct GenerateImageView: View {
    // MARK: Model Context
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PartnerKey.createdAt, order: .reverse) private var partnerKeys: [PartnerKey]
    
    @State private var selectedPartnerId: String = ""
    @State private var selectedModelId: String = ""
    
    func getSupportedModels() -> [PartnerModel] {
        if (selectedPartnerId == "") {
            return [];
        }
        
        return partnerModels.filter({ $0.modelSetType == EnumSetType.GENERATE && $0.partnerId.uuidString == selectedPartnerId })
    }
    
    func getSelectedModel() -> PartnerModel? {
        return partnerModels.first(where: { $0.modelId.uuidString == selectedModelId })
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
    func generateImage() async -> ImageSetResponse? {
        if (!isGenerating) {
            isGenerating = true
            let adapter = GenerateImageAdapter(
                imageGenerationRequest: ImageGenerationRequest(
                    modelId: getSelectedModel()!.modelId.uuidString,
                    prompt: prompt,
                    negativePrompt: negativePrompt,
                    artVariant: artVariant,
                    artQuality: artQuality,
                    artStyle: artStyle,
                    artDimensions: artDimensions,
                    partnerKey: partnerKeys.first(where: { $0.partnerId == getSelectedModel()!.partnerId })!,
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
            if (selectedModelId != "" && !partnerKeys.isEmpty) {
                Form {
                    Section(header: Text("Select Model")) {
                        Picker("Partner", selection: $selectedPartnerId) {
                            ForEach(
                                partners.filter { partner in
                                    partnerKeys.contains { $0.partnerId == partner.partnerId } &&
                                    partnerModels.contains { $0.partnerId == partner.partnerId && $0.modelSetType == .GENERATE }
                                }, id: \.partnerId
                            ) { partner in
                                HStack {
                                    #if !os(macOS)
                                    Image("\(partner.partnerCode)_square".lowercased())
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                    #endif
                                    Text(partner.partnerName)
                                }
                                .tag(partner.partnerId.uuidString)
                            }
                        }
                        #if !os(macOS)
                        .pickerStyle(.navigationLink)
                        #endif
                        .onChange(of: selectedPartnerId) {
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
                            let supportedDimensions = getSelectedModel()?.modelSupportedImageDimensions ?? []
                            
                            if (artDimensions == "") {
                                artDimensions = supportedDimensions.first ?? ""
                            } else if (!supportedDimensions.contains(artDimensions)) {
                                artDimensions = supportedDimensions.first ?? ""
                            }
                        }
                    }
                    .disabled(isGenerating)
                    
                    Section(header: Text("What do you want to generate?")) {
                        TextField("Describe your image", text: $prompt, prompt: Text("Eg. Landscape view of a city"), axis: .vertical)
                            .lineLimit(2...8)
                            .focused($focusedField, equals: .prompt)
                        if (getSelectedModel()?.modelNegativePromptSupport ?? false) {
                            TextField("Negative prompt (if any)", text: $negativePrompt, prompt: Text("Eg. Without any clouds"), axis: .vertical)
                                .lineLimit(2...8)
                                .focused($focusedField, equals: .negativePrompt)
                        }
                    }
                    .disabled(isGenerating)
                    
                    Section("Art Details") {
                        Picker("Dimensions", selection: $artDimensions) {
                            ForEach(getSelectedModel()?.modelSupportedImageDimensions ?? [], id: \.self) { dimension in
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
                        Picker("Quality", selection: $artQuality) {
                            ForEach(EnumArtQuality.allCases, id: \.self) { quality in
                                HStack {
                                    #if !os(macOS)
                                    Image("symbol_quality_\(quality.rawValue)".lowercased())
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                    #endif
                                    Text(quality.rawValue)
                                }
                                .tag(quality)
                            }
                        }
                        #if !os(macOS)
                        .pickerStyle(.navigationLink)
                        #endif
                        
                        Picker("Art Style", selection: $artVariant) {
                            ForEach(EnumArtVariant.allCases, id: \.self) { variant in
                                Text(variant.rawValue).tag(variant)
                            }
                        }
                        #if !os(macOS)
                        .pickerStyle(.navigationLink)
                        #endif
                        
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
                        
                        Picker("Number of images", selection: $numberOfImages) {
                            ForEach(1...4, id: \.self) { count in
                                Text("\(count)").tag(count)
                            }
                        }
                        #if !os(macOS)
                        .pickerStyle(.navigationLink)
                        #endif
                    }
                    .disabled(isGenerating)
                    
                    Section(header: Text("Optional enhancements")) {
                        Toggle("Auto-enhance prompt?", isOn: $promptEnhanceOpted)
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
                            }
                        }
                    }
                    .disabled(isGenerating)
                }
                .formStyle(.grouped)
            } else {
                Text("Please connect a partner")
            }
        }
        .onAppear() {
            if !partnerKeys.isEmpty && selectedModelId.isEmpty {
                let supportedPartners = partners.filter { partner in
                    partnerKeys.contains { $0.partnerId == partner.partnerId } &&
                    partnerModels.contains { $0.partnerId == partner.partnerId && $0.modelSetType == .GENERATE }
                }

                if let firstSupportedPartner = supportedPartners.first,
                   let key = partnerKeys.first(where: { $0.partnerId == firstSupportedPartner.partnerId }) {
                    
                    selectedPartnerId = key.partnerId.uuidString
                    selectedModelId = getSupportedModels().first?.modelId.uuidString ?? ""
                    
                    if !selectedPartnerId.isEmpty, !selectedModelId.isEmpty {
                        artDimensions = getSelectedModel()?.modelSupportedImageDimensions.first ?? ""
                    }
                }
            }
        }
        .navigationDestination(isPresented: $isNavigationActive) {
            if (selectedSetId != nil) {
                GenerationImageView(setId: selectedSetId!)
            }
        }
        .navigationTitle("Generate Image")
    }
}
