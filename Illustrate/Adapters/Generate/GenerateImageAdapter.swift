import Foundation
import CloudKit
import SwiftData

enum EnumGenerateImageAdapterErrorCode: String, Codable {
    case GENERATOR_ERROR = "Internal Generator Error"
    case MODEL_ERROR = "Partner Model Error"
    case ADAPTER_ERROR = "Internal Adapter Error"
    case TRANSFORM_RESPONSE_ERROR = "Internal Response Transform Error"
}

struct ImageEditDirection: Codable {
    var left: Int
    var right: Int
    var up: Int
    var down: Int
}

struct ImageGenerationRequest: Codable {
    var modelId: String
    var prompt: String
    var searchPrompt: String?
    var negativePrompt: String?
    var artVariant: EnumArtVariant = EnumArtVariant.NORMAL
    var artQuality: EnumArtQuality = EnumArtQuality.HD
    var artStyle: EnumArtStyle = EnumArtStyle.VIVID
    var artDimensions: String
    var clientImage: String?
    var clientMask: String?
    var partnerKey: PartnerKey
    var numberOfImages: Int = 1
    var editDirection: ImageEditDirection?
}

struct ImageGenerationResponse: Codable {
    var generationId: UUID?
    var status: EnumGenerationStatus
    var base64: String?
    var size: Int?
    var cost: Double?
    var modelPrompt: String?
    var colorPalette: [String]?
    var errorCode: EnumGenerateImageAdapterErrorCode?
    var errorMessage: String?
}

struct ImageSetResponse: Codable {
    var status: EnumGenerationStatus
    var set: ImageSet?
    var generations: [Generation]?
    var errorCode: EnumGenerateImageAdapterErrorCode?
    var errorMessage: String?
}

protocol ImageGenerationProtocol {
    var model: PartnerModel { get }
    
    associatedtype ServiceRequest
    
    func transformRequest(request: ImageGenerationRequest) -> ServiceRequest
    func transformResponse(request: ImageGenerationRequest, response: NetworkResponseData) throws -> ImageGenerationResponse
    func getCreditsUsed(request: ImageGenerationRequest) -> Double
    func makeRequest(request: ImageGenerationRequest) async throws -> ImageGenerationResponse
}

func getImageGenerationAdapter(imageGenerationRequest: ImageGenerationRequest) throws -> any ImageGenerationProtocol {
    let model = partnerModels.first(where: { $0.modelId.uuidString == imageGenerationRequest.modelId })
    if (model == nil) {
        throw NSError(domain: "Unknown model", code: -1, userInfo: nil)
    }
    
    switch model!.modelCode {
    case EnumPartnerModelCode.OPENAI_DALLE3:
        return G_OPENAI_DALLE3()
    case EnumPartnerModelCode.STABILITY_CORE:
        return G_STABILITY_CORE()
    case EnumPartnerModelCode.STABILITY_SDXL:
        return G_STABILITY_SDXL()
    case EnumPartnerModelCode.STABILITY_ULTRA:
        return G_STABILITY_ULTRA()
    case EnumPartnerModelCode.STABILITY_SD3:
        return G_STABILITY_SD3()
    case EnumPartnerModelCode.STABILITY_SD3_TURBO:
        return G_STABILITY_SD3()
    case EnumPartnerModelCode.STABILITY_CREATIVE_UPSCALE:
        return G_STABILITY_CREATIVE_UPSCALE()
    case EnumPartnerModelCode.STABILITY_CONSERVATIVE_UPSCALE:
        return G_STABILITY_CONSERVATIVE_UPSCALE()
    case EnumPartnerModelCode.STABILITY_OUTPAINT:
        return G_STABILITY_OUTPAINT()
    case EnumPartnerModelCode.STABILITY_INPAINT:
        return G_STABILITY_INPAINT()
    case EnumPartnerModelCode.STABILITY_ERASE:
        return G_STABILITY_ERASE()
    case EnumPartnerModelCode.STABILITY_SEARCH_AND_REPLACE:
        return G_STABILITY_SEARCH_AND_REPLACE()
    case EnumPartnerModelCode.STABILITY_REMOVE_BACKGROUND:
        return G_STABILITY_REMOVE_BACKGROUND()
    case EnumPartnerModelCode.REPLICATE_FLUX_SCHNELL:
        return G_REPLICATE_FLUX_SCHNELL()
    case EnumPartnerModelCode.REPLICATE_FLUX_DEV:
        return G_REPLICATE_FLUX_DEV()
    case EnumPartnerModelCode.REPLICATE_FLUX_DEV_EDIT:
        return G_REPLICATE_FLUX_DEV_EDIT()
    case EnumPartnerModelCode.REPLICATE_FLUX_PRO:
        return G_REPLICATE_FLUX_PRO()
    default:
        throw NSError(domain: "Unknown model", code: -1, userInfo: nil)
    }
}

func getImageSizeInBytes(imageURL: URL) -> Int? {
    if let imageData = try? Data(contentsOf: imageURL) {
        return imageData.count
    }
    return nil
}

func uploadImageToCloudKit(record: CKRecord) async -> Bool {
    let privateDatabase = CKContainer.default().privateCloudDatabase
    do {
        let ckRecord: CKRecord = try await privateDatabase.save(record)
        
        return ckRecord.recordID.recordName == record.recordID.recordName
    } catch {
        print("Error uploading image: \(error)")
        return false
    }
}

func saveImageToDocumentsDirectory(imageData: Data, withName name: String) -> URL? {
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let imageFileURL = documentsURL.appendingPathComponent("\(name).png")
    
    do {
        try imageData.write(to: imageFileURL)
        print("Image saved to: \(imageFileURL.path)")
        return imageFileURL
    } catch {
        print("Error saving image: \(error)")
        return nil
    }
}

class GenerateImageAdapter {
    let imageGenerationRequest: ImageGenerationRequest
    let modelContext: ModelContext
    
    init(imageGenerationRequest: ImageGenerationRequest, modelContext: ModelContext) {
        self.imageGenerationRequest = imageGenerationRequest
        self.modelContext = modelContext
    }
    
    func atomicRequest(imageGenerationRequest: ImageGenerationRequest, generationAdapter: any ImageGenerationProtocol) async -> ImageGenerationResponse {
        do {
            let generation = try await generationAdapter.makeRequest(request: imageGenerationRequest)
            if (generation.base64 == nil) {
                if (generation.errorCode != nil) {
                    return ImageGenerationResponse(
                        status: EnumGenerationStatus.FAILED,
                        errorCode: generation.errorCode,
                        errorMessage: generation.errorMessage
                    )
                }
                
                throw NSError(domain: "Failed to generate image", code: -1, userInfo: nil)
            }
            
            if let imageData = Data(base64Encoded: generation.base64!) {
                let uuid = UUID()
                let fileUrl: URL? = saveImageToDocumentsDirectory(imageData: imageData, withName: uuid.uuidString)
                if (fileUrl != nil) {
                    // Save optimised version
                    let image: PlatformImage? = toPlatformImage(base64: generation.base64!)
                    if (image != nil) {
                        let optimised50 = image!.resizeImage(scale: 0.50)
                        if (optimised50 != nil) {
                            if let optimised50Data = Data(base64Encoded: optimised50!) {
                                _ = saveImageToDocumentsDirectory(imageData: optimised50Data, withName: "\(uuid)_o50")
                            }
                        }
                        
                        let optimised20 = image!.resizeImage(scale: 0.20)
                        if (optimised20 != nil) {
                            if let optimised20Data = Data(base64Encoded: optimised20!) {
                                _ = saveImageToDocumentsDirectory(imageData: optimised20Data, withName: "\(uuid)_o20")
                            }
                        }
                        
                        let optimised04 = image!.resizeImage(scale: 0.04)
                        if (optimised04 != nil) {
                            if let optimised04Data = Data(base64Encoded: optimised04!) {
                                _ = saveImageToDocumentsDirectory(imageData: optimised04Data, withName: "\(uuid)_o04")
                            }
                        }
                    }
                    
                    // Save client image
                    if (imageGenerationRequest.clientImage != nil) {
                        let _: URL? = saveImageToDocumentsDirectory(
                            imageData: Data(base64Encoded: imageGenerationRequest.clientImage!)!,
                            withName: "\(uuid)_client"
                        )
                    }
                    
                    // Save client mask
                    if (imageGenerationRequest.clientMask != nil) {
                        let _: URL? = saveImageToDocumentsDirectory(
                            imageData: Data(base64Encoded: imageGenerationRequest.clientMask!)!,
                            withName: "\(uuid)_mask"
                        )
                    }
                    
                    return ImageGenerationResponse(
                        generationId: uuid,
                        status: EnumGenerationStatus.GENERATED,
                        base64: nil,
                        size: getImageSizeInBytes(imageURL: fileUrl!),
                        cost: generation.cost,
                        modelPrompt: generation.modelPrompt,
                        colorPalette: getDominantColors(imageURL: fileUrl!)
                    )
                } else {
                    throw NSError(domain: "Could not save image", code: -1, userInfo: nil)
                }
            } else {
                throw NSError(domain: "Could not decode base64", code: -1, userInfo: nil)
            }
        } catch {
            return ImageGenerationResponse(
                status: EnumGenerationStatus.FAILED,
                errorCode: EnumGenerateImageAdapterErrorCode.GENERATOR_ERROR,
                errorMessage: "Failed with error: \(error)"
            )
        }
    }

    func makeRequest() async -> ImageSetResponse {
        do {
            let generationAdapter: any ImageGenerationProtocol = try getImageGenerationAdapter(imageGenerationRequest: imageGenerationRequest)
            
            var imageGenerationResponses: [ImageGenerationResponse] = []
            await withTaskGroup(of: ImageGenerationResponse?.self) { group in
                for _ in 0..<imageGenerationRequest.numberOfImages {
                    group.addTask {
                        return await self.atomicRequest(
                            imageGenerationRequest: self.imageGenerationRequest,
                            generationAdapter: generationAdapter
                        )
                    }
                }
                
                for await generation in group {
                    if let generation = generation {
                        imageGenerationResponses.append(generation)
                    }
                }
            }
            
            if (imageGenerationResponses.isEmpty) {
                return ImageSetResponse(
                    status: EnumGenerationStatus.FAILED,
                    errorCode: EnumGenerateImageAdapterErrorCode.GENERATOR_ERROR,
                    errorMessage: "No generation was successful"
                )
            }
            
            for generation in imageGenerationResponses {
                if (generation.status == EnumGenerationStatus.FAILED || generation.generationId == nil) {
                    return ImageSetResponse(
                        status: EnumGenerationStatus.FAILED,
                        errorCode: generation.errorCode ?? EnumGenerateImageAdapterErrorCode.GENERATOR_ERROR,
                        errorMessage: generation.errorMessage ?? "Failed with unknown error"
                    )
                }
            }
            
            let usedModel = partnerModels.first(where: { $0.modelId.uuidString == imageGenerationRequest.modelId })
            
            let set: ImageSet = ImageSet(
                prompt: imageGenerationRequest.prompt,
                modelId: imageGenerationRequest.modelId,
                artStyle: imageGenerationRequest.artStyle,
                artVariant: imageGenerationRequest.artVariant,
                artDimensions: imageGenerationRequest.artDimensions,
                setType: usedModel!.modelSetType,
                negativePrompt: imageGenerationRequest.negativePrompt,
                searchPrompt: nil
            )
            
            modelContext.insert(set)
            try? modelContext.save()
            
            let generations: [Generation] = imageGenerationResponses.map { generation in
                let generation = Generation(
                    id: generation.generationId!,
                    setId: set.id,
                    modelId: imageGenerationRequest.modelId,
                    prompt: imageGenerationRequest.prompt,
                    promptEnhanceOpted: false,
                    promptAfterEnhance: "",
                    artStyle: imageGenerationRequest.artStyle,
                    artVariant: imageGenerationRequest.artVariant,
                    artQuality: imageGenerationRequest.artQuality,
                    artDimensions: imageGenerationRequest.artDimensions,
                    size: generation.size ?? 0,
                    creditUsed: generation.cost ?? 0,
                    status: generation.status,
                    colorPalette: generation.colorPalette ?? [],
                    modelRevisedPrompt: generation.modelPrompt,
                    clientImage: imageGenerationRequest.clientImage,
                    clientMask: nil,
                    negativePrompt: imageGenerationRequest.negativePrompt,
                    searchPrompt: nil,
                    contentType: EnumGenerationContentType.IMAGE_2D
                )
                
                modelContext.insert(generation)
                try? modelContext.save()
                
                return generation
            }
            
            return ImageSetResponse(
                status: EnumGenerationStatus.GENERATED,
                set: set,
                generations: generations
            )
            
        } catch {
            return ImageSetResponse(
                status: EnumGenerationStatus.FAILED,
                errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Failed with error: \(error)"
            )
        }
    }

}
