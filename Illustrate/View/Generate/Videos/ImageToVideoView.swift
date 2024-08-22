import SwiftUI
import SwiftData
import PhotosUI

struct ImageToVideoView: View {
    // MARK: Model Context
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PartnerKey.createdAt, order: .reverse) private var partnerKeys: [PartnerKey]
    
    @State private var selectedPartnerId: String = ""
    @State private var selectedModelId: String = ""
    
    func getSupportedModels() -> [PartnerModel] {
        if (selectedPartnerId == "") {
            return [];
        }
        
        return partnerModels.filter({ $0.modelSetType == EnumSetType.VIDEO_IMAGE && $0.partnerId.uuidString == selectedPartnerId })
    }
    
    func getSelectedModel() -> PartnerModel? {
        return partnerModels.first(where: { $0.modelId.uuidString == selectedModelId })
    }
    
    // MARK: Form States
    @State private var artDimensions: String = ""
    @State private var motion: Double = 135
    @State private var stickyness: Double = 2.0
    
    // MARK: Photo States
    @State private var isPhotoPickerOpen: Bool = false
    
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var selectedImage: PlatformImage?
    @State private var colorPalette: [String] = []
    
    @State private var isCropSheetOpen: Bool = false
    
    // MARK: Generation States
    @State private var isGenerating: Bool = false
    func generateVideo() async -> VideoSetResponse? {
        if (!isGenerating) {
            isGenerating = true
            let adapter = GenerateVideoAdapter(
                videoGenerationRequest: VideoGenerationRequest(
                    modelId: getSelectedModel()!.modelId.uuidString,
                    artDimensions: artDimensions,
                    clientImage: selectedImage?.toBase64PNG(),
                    partnerKey: partnerKeys.first(where: { $0.partnerId == getSelectedModel()!.partnerId })!,
                    motion: Int(motion),
                    stickyness: Int(stickyness)
                ),
                modelContext: modelContext
            )
            
            let response: VideoSetResponse = await adapter.makeRequest()
            
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
                                    partnerModels.contains { $0.partnerId == partner.partnerId && $0.modelSetType == .VIDEO_IMAGE }
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
                                    .shadow(color: .black.opacity(0.4), radius: 8)
                                    .padding(.vertical, 6)
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
                                        isPhotoPickerOpen = true
                                    }
                            }
                        }
                        
                        HStack {
                            Spacer()
                            Button(selectedImage != nil ? "Change image" : "Select image") {
                                isPhotoPickerOpen = true
                            }
                            Spacer()
                        }
                    }
                    
                    Section("Video Preferences") {
                        Slider(value: $motion, in: 15...255, step: 15) {
                            Text("Motion: \(Int(motion / 255 * 100))% (\(Int(motion)))")
                        }
                        Slider(value: $stickyness, in: 0...10, step: 0.5) {
                            Text("Stickyness: \(Int(stickyness * 10))% \(stickyness, specifier: "%.1f")")
                        }
                    }
                    .disabled(isGenerating)
                    
                    Button(
                        isGenerating ? "Generating, please wait..." : "Generate Video"
                    ) {
                        Task {
                            let response = await generateVideo()
                            if (response?.status == EnumGenerationStatus.GENERATED && response?.set?.id != nil) {
                                selectedSetId = response!.set!.id
                                isNavigationActive = true
                            }
                        }
                    }
                    .disabled(isGenerating)
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
                            selectedImage = image.resizeImage(targetSize: CGSize(
                                width: getAspectRatio(dimension: artDimensions).actualWidth,
                                height: getAspectRatio(dimension: artDimensions).actualHeight
                            ))
                            
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
                    partnerModels.contains { $0.partnerId == partner.partnerId && $0.modelSetType == .VIDEO_IMAGE }
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
                GenerationVideoView(setId: selectedSetId!)
            }
        }
        .navigationTitle("Image to Video")
    }
}
