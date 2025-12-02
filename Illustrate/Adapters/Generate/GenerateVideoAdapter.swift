import CloudKit
import Foundation
import SwiftData

enum EnumGenerateVideoAdapterErrorCode: String, Codable {
    case GENERATOR_ERROR = "Internal Generator Error"
    case MODEL_ERROR = "Connection Model Error"
    case ADAPTER_ERROR = "Internal Adapter Error"
    case TRANSFORM_RESPONSE_ERROR = "Internal Response Transform Error"
}

struct VideoGenerationRequest: Codable {
    var modelId: String
    var prompt: String?
    var searchPrompt: String?
    var negativePrompt: String?
    var artDimensions: String
    var clientImage: String?
    var clientMask: String?
    var clientLastFrame: String?
    var clientVideo: String?
    var connectionKey: ConnectionKey
    var connectionSecret: String
    var numberOfVideos: Int = 1
    var motion: Int?
    var stickyness: Int?
    var durationSeconds: Int?
    var resolution: String?
    var generateAudio: Bool?
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
    var model: ConnectionModel { get }

    associatedtype ServiceRequest

    func transformRequest(request: VideoGenerationRequest) -> ServiceRequest
    func transformResponse(request: VideoGenerationRequest, response: NetworkResponseData) throws -> VideoGenerationResponse
    func getCreditsUsed(request: VideoGenerationRequest) -> Double
    func makeRequest(request: VideoGenerationRequest) async throws -> VideoGenerationResponse
}

func getVideoGenerationAdapter(videoGenerationRequest: VideoGenerationRequest) throws -> any VideoGenerationProtocol {
    guard let model = ConnectionService.shared.model(by: videoGenerationRequest.modelId) else {
        throw NSError(domain: "Unknown model", code: -1, userInfo: nil)
    }

    switch model.modelCode {
    case EnumConnectionModelCode.STABILITY_IMAGE_TO_VIDEO:
        return G_STABILITY_IMAGE_TO_VIDEO()
    case EnumConnectionModelCode.GOOGLE_VEO_31:
        return G_GOOGLE_VEO_31()
    case EnumConnectionModelCode.GOOGLE_VEO_31_FAST:
        return G_GOOGLE_VEO_31_FAST()
    case EnumConnectionModelCode.GOOGLE_VEO_3:
        return G_GOOGLE_VEO_3()
    case EnumConnectionModelCode.GOOGLE_VEO_3_FAST:
        return G_GOOGLE_VEO_3_FAST()
    case EnumConnectionModelCode.GOOGLE_VEO_2:
        return G_GOOGLE_VEO_2()
    default:
        throw NSError(domain: "Unknown model", code: -1, userInfo: nil)
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
            if generation.base64 == nil {
                return VideoGenerationResponse(
                    status: EnumGenerationStatus.FAILED,
                    errorCode: generation.errorCode != nil ? generation.errorCode : EnumGenerateVideoAdapterErrorCode.GENERATOR_ERROR,
                    errorMessage: generation.errorMessage != nil ? generation.errorMessage : "Failed with unknown error"
                )
            }

            if let videoData = Data(base64Encoded: generation.base64!) {
                let uuid = UUID()
                saveVideoToiCloud(videoData: videoData, fileName: uuid.uuidString)

                let fileUrl: URL? = saveVideoToDocumentsDirectory(videoData: videoData, withName: uuid.uuidString)
                if fileUrl != nil {
                    let frameBase64 = await extractFirstFrameFromVideo(base64Video: generation.base64!)
                    if frameBase64 != nil {
                        let _: URL? = saveImageToDocumentsDirectory(
                            imageData: Data(base64Encoded: frameBase64!)!,
                            withName: "\(uuid)"
                        )
                        toPlatformImage(base64: frameBase64!)?.saveToiCloud(fileName: "\(uuid)")
                    }

                    let image: PlatformImage? = toPlatformImage(base64: frameBase64!)
                    if image != nil {
                        let optimised50 = image!.resizeImage(scale: 0.50)
                        if optimised50 != nil {
                            if let optimised50Data = Data(base64Encoded: optimised50!) {
                                _ = saveImageToDocumentsDirectory(imageData: optimised50Data, withName: ".\(uuid)_o50")
                                toPlatformImage(base64: optimised50!)?.saveToiCloud(fileName: ".\(uuid)_o50")
                            }
                        }

                        let optimised20 = image!.resizeImage(scale: 0.20)
                        if optimised20 != nil {
                            if let optimised20Data = Data(base64Encoded: optimised20!) {
                                _ = saveImageToDocumentsDirectory(imageData: optimised20Data, withName: ".\(uuid)_o20")
                                toPlatformImage(base64: optimised20!)?.saveToiCloud(fileName: ".\(uuid)_o20")
                            }
                        }

                        let optimised04 = image!.resizeImage(scale: 0.04)
                        if optimised04 != nil {
                            if let optimised04Data = Data(base64Encoded: optimised04!) {
                                _ = saveImageToDocumentsDirectory(imageData: optimised04Data, withName: ".\(uuid)_o04")
                                toPlatformImage(base64: optimised04!)?.saveToiCloud(fileName: ".\(uuid)_o04")
                            }
                        }
                    }

                    if videoGenerationRequest.clientImage != nil {
                        let _: URL? = saveImageToDocumentsDirectory(
                            imageData: Data(base64Encoded: videoGenerationRequest.clientImage!)!,
                            withName: ".\(uuid)_client"
                        )
                        toPlatformImage(base64: videoGenerationRequest.clientImage!)?.saveToiCloud(fileName: ".\(uuid)_client")
                    }

                    if videoGenerationRequest.clientMask != nil {
                        let _: URL? = saveImageToDocumentsDirectory(
                            imageData: Data(base64Encoded: videoGenerationRequest.clientMask!)!,
                            withName: ".\(uuid)_mask"
                        )
                        toPlatformImage(base64: videoGenerationRequest.clientMask!)?.saveToiCloud(fileName: ".\(uuid)_mask")
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
                    return VideoGenerationResponse(
                        status: EnumGenerationStatus.FAILED,
                        errorCode: EnumGenerateVideoAdapterErrorCode.GENERATOR_ERROR,
                        errorMessage: "Could not save image"
                    )
                }
            } else {
                return VideoGenerationResponse(
                    status: EnumGenerationStatus.FAILED,
                    errorCode: EnumGenerateVideoAdapterErrorCode.GENERATOR_ERROR,
                    errorMessage: "Could not decode base64"
                )
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
                for _ in 0 ..< videoGenerationRequest.numberOfVideos {
                    group.addTask {
                        await self.atomicRequest(
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

            if videoGenerationResponses.isEmpty {
                return VideoSetResponse(
                    status: EnumGenerationStatus.FAILED,
                    errorCode: EnumGenerateVideoAdapterErrorCode.GENERATOR_ERROR,
                    errorMessage: "No generation was successful"
                )
            }

            for generation in videoGenerationResponses {
                if generation.status == EnumGenerationStatus.FAILED || generation.generationId == nil {
                    return VideoSetResponse(
                        status: EnumGenerationStatus.FAILED,
                        errorCode: generation.errorCode ?? EnumGenerateVideoAdapterErrorCode.GENERATOR_ERROR,
                        errorMessage: generation.errorMessage ?? "Failed with unknown error"
                    )
                }
            }

            guard let usedModel = ConnectionService.shared.model(by: videoGenerationRequest.modelId) else {
                return VideoSetResponse(
                    status: EnumGenerationStatus.FAILED,
                    errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                    errorMessage: "Model not found for ID: \(videoGenerationRequest.modelId)"
                )
            }

            let set: ImageSet = .init(
                prompt: videoGenerationRequest.prompt ?? "",
                modelId: videoGenerationRequest.modelId,
                artDimensions: videoGenerationRequest.artDimensions,
                setType: usedModel.modelSetType,
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
