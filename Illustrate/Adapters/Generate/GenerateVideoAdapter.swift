import Foundation
import CloudKit
import SwiftData

enum EnumGenerateVideoAdapterErrorCode: String, Codable {
    case GENERATOR_ERROR = "GENERATOR_ERROR"
    case MODEL_ERROR = "MODEL_ERROR"
    case ADAPTER_ERROR = "ADAPTER_ERROR"
    case TRANSFORM_RESPONSE_ERROR = "TRANSFORM_RESPONSE_ERROR"
}

struct VideoGenerationRequest: Codable {
    var modelId: String
    var prompt: String?
    var searchPrompt: String?
    var negativePrompt: String?
    var artDimensions: String
    var clientImage: String?
    var clientMask: String?
    var partnerKey: PartnerKey
    var numberOfVideos: Int = 1
    var motion: Int?
    var stickyness: Int?
}

struct VideoGenerationResponse: Codable {
    var generationId: UUID?
    var status: EnumGenerationStatus
    var base64: String?
    var size: Int?
    var cost: Double?
    var modelPrompt: String?
    var colorPalette: [String]?
    var errorCode: EnumGenerateVideoAdapterErrorCode?
    var errorMessage: String?
}

struct VideoSetResponse: Codable {
    var status: EnumGenerationStatus
    var set: ImageSet?
    var generations: [Generation]?
    var errorCode: EnumGenerateVideoAdapterErrorCode?
    var errorMessage: String?
}

protocol VideoGenerationProtocol {
    var model: PartnerModel { get }
    
    associatedtype ServiceRequest
    
    func transformRequest(request: VideoGenerationRequest) -> ServiceRequest
    func transformResponse(request: VideoGenerationRequest, response: NetworkResponseData) throws -> VideoGenerationResponse
    func getCreditsUsed(request: VideoGenerationRequest) -> Double
    func makeRequest(request: VideoGenerationRequest) async throws -> VideoGenerationResponse
}

func getVideoGenerationAdapter(videoGenerationRequest: VideoGenerationRequest) throws -> any VideoGenerationProtocol {
    let model = partnerModels.first(where: { $0.modelId.uuidString == videoGenerationRequest.modelId })
    if (model == nil) {
        throw NSError(domain: "Unknown model", code: -1, userInfo: nil)
    }
    
    switch model!.modelCode {
    case EnumPartnerModelCode.STABILITY_IMAGE_TO_VIDEO:
        return G_STABILITY_IMAGE_TO_VIDEO()
    default:
        throw NSError(domain: "Unknown model", code: -1, userInfo: nil)
    }
}

func getVideoSizeInBytes(videoURL: URL) -> Int? {
    if let imageData = try? Data(contentsOf: videoURL) {
        return imageData.count
    }
    return nil
}

func uploadVideoToCloudKit(record: CKRecord) async -> Bool {
    let privateDatabase = CKContainer.default().privateCloudDatabase
    do {
        let ckRecord: CKRecord = try await privateDatabase.save(record)
        
        return ckRecord.recordID.recordName == record.recordID.recordName
    } catch {
        print("Error uploading video: \(error)")
        return false
    }
}

func saveVideoToDocumentsDirectory(videoData: Data, withName name: String) -> URL? {
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let videoFileURL = documentsURL.appendingPathComponent("\(name).mp4")
    
    do {
        try videoData.write(to: videoFileURL)
        print("Image saved to: \(videoFileURL.path)")
        return videoFileURL
    } catch {
        print("Error saving image: \(error)")
        return nil
    }
}

class GenerateVideoAdapter {
    let videoGenerationRequest: VideoGenerationRequest
    let modelContext: ModelContext
    
    init(videoGenerationRequest: VideoGenerationRequest, modelContext: ModelContext) {
        self.videoGenerationRequest = videoGenerationRequest
        self.modelContext = modelContext
    }
    
    func atomicRequest(videoGenerationRequest: VideoGenerationRequest, generationAdapter: any VideoGenerationProtocol) async -> VideoGenerationResponse {
        do {
            let generation = try await generationAdapter.makeRequest(request: videoGenerationRequest)
            if (generation.base64 == nil) {
                if (generation.errorCode != nil) {
                    return VideoGenerationResponse(
                        status: EnumGenerationStatus.FAILED,
                        errorCode: generation.errorCode,
                        errorMessage: generation.errorMessage
                    )
                }
                
                throw NSError(domain: "Failed to generate image", code: -1, userInfo: nil)
            }
            
            if let videoData = Data(base64Encoded: generation.base64!) {
                let uuid = UUID()
                let fileUrl: URL? = saveVideoToDocumentsDirectory(videoData: videoData, withName: uuid.uuidString)
                if (fileUrl != nil) {
                    // Create thumbnail
                    let frameBase64 = extractFirstFrameFromVideo(base64Video: generation.base64!)
                    if (frameBase64 != nil) {
                        let _: URL? = saveImageToDocumentsDirectory(
                            imageData: Data(base64Encoded: frameBase64!)!,
                            withName: "\(uuid)"
                        )
                    }
                    
                    // Save optimised version
                    let image: PlatformImage? = toPlatformImage(base64: frameBase64!)
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
                    if (videoGenerationRequest.clientImage != nil) {
                        let _: URL? = saveImageToDocumentsDirectory(
                            imageData: Data(base64Encoded: videoGenerationRequest.clientImage!)!,
                            withName: "\(uuid)_client"
                        )
                    }
                    
                    // Save client mask
                    if (videoGenerationRequest.clientMask != nil) {
                        let _: URL? = saveImageToDocumentsDirectory(
                            imageData: Data(base64Encoded: videoGenerationRequest.clientMask!)!,
                            withName: "\(uuid)_mask"
                        )
                    }
                    
                    return VideoGenerationResponse(
                        generationId: uuid,
                        status: EnumGenerationStatus.GENERATED,
                        base64: nil,
                        size: getVideoSizeInBytes(videoURL: fileUrl!),
                        cost: generation.cost,
                        modelPrompt: generation.modelPrompt,
                        colorPalette: []
                    )
                } else {
                    throw NSError(domain: "Could not save image", code: -1, userInfo: nil)
                }
            } else {
                throw NSError(domain: "Could not decode base64", code: -1, userInfo: nil)
            }
        } catch {
            return VideoGenerationResponse(
                status: EnumGenerationStatus.FAILED,
                errorCode: EnumGenerateVideoAdapterErrorCode.GENERATOR_ERROR,
                errorMessage: "Failed with error: \(error)"
            )
        }
    }

    func makeRequest() async -> VideoSetResponse {
        do {
            let generationAdapter: any VideoGenerationProtocol = try getVideoGenerationAdapter(videoGenerationRequest: videoGenerationRequest)
            
            var videoGenerationResponses: [VideoGenerationResponse] = []
            await withTaskGroup(of: VideoGenerationResponse?.self) { group in
                for _ in 0..<videoGenerationRequest.numberOfVideos {
                    group.addTask {
                        return await self.atomicRequest(
                            videoGenerationRequest: self.videoGenerationRequest,
                            generationAdapter: generationAdapter
                        )
                    }
                }
                
                for await generation in group {
                    if let generation = generation {
                        videoGenerationResponses.append(generation)
                    }
                }
            }
            
            if (videoGenerationResponses.isEmpty) {
                return VideoSetResponse(
                    status: EnumGenerationStatus.FAILED,
                    errorCode: EnumGenerateVideoAdapterErrorCode.GENERATOR_ERROR,
                    errorMessage: "No generation was successful"
                )
            }
            
            for generation in videoGenerationResponses {
                if (generation.status == EnumGenerationStatus.FAILED || generation.generationId == nil) {
                    return VideoSetResponse(
                        status: EnumGenerationStatus.FAILED,
                        errorCode: generation.errorCode ?? EnumGenerateVideoAdapterErrorCode.GENERATOR_ERROR,
                        errorMessage: generation.errorMessage ?? "Failed with unknown error"
                    )
                }
            }
            
            let usedModel = partnerModels.first(where: { $0.modelId.uuidString == videoGenerationRequest.modelId })
            
            let set: ImageSet = ImageSet(
                prompt: videoGenerationRequest.prompt ?? "",
                modelId: videoGenerationRequest.modelId,
                artDimensions: videoGenerationRequest.artDimensions,
                setType: usedModel!.modelSetType,
                negativePrompt: videoGenerationRequest.negativePrompt,
                searchPrompt: nil
            )
            
            modelContext.insert(set)
            try? modelContext.save()
            
            let generations: [Generation] = videoGenerationResponses.map { generation in
                let generation = Generation(
                    id: generation.generationId!,
                    setId: set.id,
                    modelId: videoGenerationRequest.modelId,
                    prompt: videoGenerationRequest.prompt ?? "",
                    promptEnhanceOpted: false,
                    promptAfterEnhance: "",
                    artDimensions: videoGenerationRequest.artDimensions,
                    size: generation.size ?? 0,
                    creditUsed: generation.cost ?? 0,
                    status: generation.status,
                    colorPalette: generation.colorPalette ?? [],
                    modelRevisedPrompt: generation.modelPrompt,
                    clientImage: videoGenerationRequest.clientImage,
                    clientMask: nil,
                    negativePrompt: videoGenerationRequest.negativePrompt,
                    searchPrompt: nil,
                    contentType: EnumGenerationContentType.VIDEO
                )
                
                modelContext.insert(generation)
                try? modelContext.save()
                
                return generation
            }
            
            return VideoSetResponse(
                status: EnumGenerationStatus.GENERATED,
                set: set,
                generations: generations
            )
            
        } catch {
            return VideoSetResponse(
                status: EnumGenerationStatus.FAILED,
                errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Failed with error: \(error)"
            )
        }
    }

}
