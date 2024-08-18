import SwiftUI
import SwiftData
import PhotosUI

struct EditMaskImageView: View {
    // MARK: Model Context
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PartnerKey.createdAt, order: .reverse) private var partnerKeys: [PartnerKey]
    
    @State private var selectedPartnerId: String = ""
    @State private var selectedModelId: String = ""
    
    func getSupportedModels() -> [PartnerModel] {
        if (selectedPartnerId == "") {
            return [];
        }
        
        return partnerModels.filter({ $0.modelSetType == EnumSetType.EDIT_MASK && $0.partnerId.uuidString == selectedPartnerId })
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
    @State private var promptEnhanceOpted: Bool = false
    
    // MARK: Photo States
    @State private var isPhotoPickerOpen: Bool = false
    
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var selectedImage: PlatformImage?
    @State private var colorPalette: [String] = []
    
    @State private var isCropSheetOpen: Bool = false
    
    @State private var maskPath = Path()
    @State private var canvasSize = CGSize.zero
        
    // MARK: Generation States
    @State private var isGenerating: Bool = false
    func generateImage() async -> ImageSetResponse? {
        if (!isGenerating) {
            do {
                isGenerating = true
                
                let clientMask: PlatformImage? = exportPathToImage(
                    path: maskPath,
                    size: canvasSize
                )
                
                let adapter = GenerateImageAdapter(
                    imageGenerationRequest: ImageGenerationRequest(
                        modelId: getSelectedModel()!.modelId.uuidString,
                        prompt: prompt,
                        negativePrompt: negativePrompt,
                        artDimensions: artDimensions,
                        clientImage: selectedImage?.toBase64PNG(),
                        clientMask: clientMask?.toBase64PNG(),
                        partnerKey: partnerKeys.first(where: { $0.partnerId == getSelectedModel()!.partnerId })!
                    ),
                    modelContext: modelContext
                )
                
                let response: ImageSetResponse = await adapter.makeRequest()
                
                isGenerating = false
                
                return response;
            }
        }
        
        return nil
    }
    
    // MARK: Navigation States
    @State private var isNavigationActive: Bool = false
    @State private var selectedSetId: UUID? = nil
    
    // MARK: View
    var body: some View {
        VStack {
            if (selectedModelId != "" && !partnerKeys.isEmpty) {
                Form {
                    Section(header: Text("Select Model")) {
                        Picker("Partner", selection: $selectedPartnerId) {
                            ForEach(
                                partners.filter { partner in
                                    partnerKeys.contains { $0.partnerId == partner.partnerId } &&
                                    partnerModels.contains { $0.partnerId == partner.partnerId && $0.modelSetType == .EDIT_MASK }
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
                                selectedImage = nil
                                colorPalette = []
                            } else if (!supportedDimensions.contains(artDimensions)) {
                                artDimensions = supportedDimensions.first ?? ""
                                selectedImage = nil
                                colorPalette = []
                            }
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
                        .onChange(of: artDimensions) {
                            selectedImage = nil
                            colorPalette = []
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
                                    .frame(maxHeight: 400)
                                    .overlay(
                                        GeometryReader { geometry in
                                            MaskDrawingView(
                                                path: $maskPath,
                                                size: geometry.size
                                            )
                                            .onAppear {
                                                canvasSize = geometry.size
                                            }
                                            .onChange(of: geometry.size) {
                                                canvasSize = geometry.size
                                            }
                                        }
                                    )
                                    .shadow(color: .black.opacity(0.4), radius: 8)
                                    .frame(maxWidth: .infinity)
                                #else
                                Image(uiImage: selectedImage!)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        GeometryReader { geometry in
                                            MaskDrawingView(
                                                path: $maskPath,
                                                size: geometry.size
                                            )
                                            .onAppear {
                                                canvasSize = geometry.size
                                            }
                                            .onChange(of: geometry.size) {
                                                canvasSize = geometry.size
                                            }
                                        }
                                    )
                                #endif
                            } else {
                                Image("placeholder_select_image")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    #if os(macOS)
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                                    #endif
                                    .onTapGesture {
                                        isPhotoPickerOpen = true
                                    }
                            }
                        }
                        .padding(.vertical, 6)
                        
                        HStack {
                            Spacer()
                            Button(selectedImage != nil ? "Change image" : "Select image") {
                                isPhotoPickerOpen = true
                            }
                            if (selectedImage != nil && !maskPath.isEmpty) {
                                Button("Clear mask") {
                                    maskPath = Path()
                                }
                            }
                            Spacer()
                        }
                    }
                    
                    Section(header: Text("Edit instructions")) {
                        TextField("What specifics do you want to enhance?", text: $prompt, prompt: Text("Eg. Face in the image"), axis: .vertical)
                            .lineLimit(2...8)
                            .focused($focusedField, equals: .prompt)
                        if (getSelectedModel()?.modelNegativePromptSupport ?? false) {
                            TextField("Negative prompt (if any)", text: $negativePrompt, prompt: Text("Enter negative prompt here"), axis: .vertical)
                                .lineLimit(2...8)
                                .focused($focusedField, equals: .negativePrompt)
                        }
                    }
                    .disabled(isGenerating)
                    
                    Section(header: Text("Optional enhancements")) {
                        Toggle("Auto-enhance prompt?", isOn: $promptEnhanceOpted)
                    }
                    .disabled(isGenerating)
                    
                    Button(
                        isGenerating ? "Editing, please wait..." : "Perform Edit"
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
                    .disabled(isGenerating || selectedImage == nil)
                }
                .formStyle(.grouped)
                .photosPicker(isPresented: $isPhotoPickerOpen, selection: $selectedImageItem, matching: .all(of: [
                    .not(.videos)
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
                                
                                maskPath = Path()
                                isCropSheetOpen = true
                            }
                        } else {
                            maskPath = Path()
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
                Text("Please connect a partner")
            }
        }
        .onAppear() {
            if !partnerKeys.isEmpty && selectedModelId.isEmpty {
                let supportedPartners = partners.filter { partner in
                    partnerKeys.contains { $0.partnerId == partner.partnerId } &&
                    partnerModels.contains { $0.partnerId == partner.partnerId && $0.modelSetType == .EDIT_MASK }
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
        .navigationTitle("Edit with Mask")
    }
}
