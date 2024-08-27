import CloudKit
import Foundation
import SwiftData

enum EnumGenerateImageAdapterErrorCode: String, Codable {
    case GENERATOR_ERROR = "Internal Generator Error"
    case MODEL_ERROR = "Connection Model Error"
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
    var artVariant: EnumArtVariant = .NORMAL
    var artQuality: EnumArtQuality = .HD
    var artStyle: EnumArtStyle = .VIVID
    var artDimensions: String
    var clientImage: String?
    var clientMask: String?
    var connectionKey: ConnectionKey
    var connectionSecret: String
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
    var model: ConnectionModel { get }

    associatedtype ServiceRequest

    func transformRequest(request: ImageGenerationRequest) -> ServiceRequest
    func transformResponse(request: ImageGenerationRequest, response: NetworkResponseData) throws -> ImageGenerationResponse
    func getCreditsUsed(request: ImageGenerationRequest) -> Double
    func makeRequest(request: ImageGenerationRequest) async throws -> ImageGenerationResponse
}

func getImageGenerationAdapter(imageGenerationRequest: ImageGenerationRequest) throws -> any ImageGenerationProtocol {
    let model = connectionModels.first(where: { $0.modelId.uuidString == imageGenerationRequest.modelId })
    if model == nil {
        throw NSError(domain: "Unknown model", code: -1, userInfo: nil)
    }

    switch model!.modelCode {
    case EnumConnectionModelCode.OPENAI_DALLE3:
        return G_OPENAI_DALLE3()
    case EnumConnectionModelCode.STABILITY_CORE:
        return G_STABILITY_CORE()
    case EnumConnectionModelCode.STABILITY_SDXL:
        return G_STABILITY_SDXL()
    case EnumConnectionModelCode.STABILITY_ULTRA:
        return G_STABILITY_ULTRA()
    case EnumConnectionModelCode.STABILITY_SD3:
        return G_STABILITY_SD3()
    case EnumConnectionModelCode.STABILITY_SD3_TURBO:
        return G_STABILITY_SD3()
    case EnumConnectionModelCode.STABILITY_CREATIVE_UPSCALE:
        return G_STABILITY_CREATIVE_UPSCALE()
    case EnumConnectionModelCode.STABILITY_CONSERVATIVE_UPSCALE:
        return G_STABILITY_CONSERVATIVE_UPSCALE()
    case EnumConnectionModelCode.STABILITY_OUTPAINT:
        return G_STABILITY_OUTPAINT()
    case EnumConnectionModelCode.STABILITY_INPAINT:
        return G_STABILITY_INPAINT()
    case EnumConnectionModelCode.STABILITY_ERASE:
        return G_STABILITY_ERASE()
    case EnumConnectionModelCode.STABILITY_SEARCH_AND_REPLACE:
        return G_STABILITY_SEARCH_AND_REPLACE()
    case EnumConnectionModelCode.STABILITY_REMOVE_BACKGROUND:
        return G_STABILITY_REMOVE_BACKGROUND()
    case EnumConnectionModelCode.REPLICATE_FLUX_SCHNELL:
        return G_REPLICATE_FLUX_SCHNELL()
    case EnumConnectionModelCode.REPLICATE_FLUX_DEV:
        return G_REPLICATE_FLUX_DEV()
    case EnumConnectionModelCode.REPLICATE_FLUX_PRO:
        return G_REPLICATE_FLUX_PRO()
    case EnumConnectionModelCode.FAL_FLUX_SCHNELL:
        return G_FAL_FLUX_SCHNELL()
    case EnumConnectionModelCode.FAL_FLUX_DEV:
        return G_FAL_FLUX_DEV()
    case EnumConnectionModelCode.FAL_FLUX_PRO:
        return G_FAL_FLUX_PRO()
    case EnumConnectionModelCode.HUGGING_FACE_FLUX_SCHNELL:
        return G_HUGGING_FACE_FLUX_SCHNELL()
    case EnumConnectionModelCode.HUGGING_FACE_FLUX_DEV:
        return G_HUGGING_FACE_FLUX_DEV()
    default:
        throw NSError(domain: "Unknown model", code: -1, userInfo: nil)
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
            if generation.base64 == nil {
                return ImageGenerationResponse(
                    status: EnumGenerationStatus.FAILED,
                    errorCode: generation.errorCode != nil ? generation.errorCode : EnumGenerateImageAdapterErrorCode.GENERATOR_ERROR,
                    errorMessage: generation.errorMessage != nil ? generation.errorMessage : "Failed with unknown error"
                )
            }

            if let imageData = Data(base64Encoded: generation.base64!) {
                let uuid = UUID()
                let image: PlatformImage? = toPlatformImage(base64: generation.base64!)
                image?.saveToiCloud(fileName: uuid.uuidString)

                let fileUrl: URL? = saveImageToDocumentsDirectory(imageData: imageData, withName: uuid.uuidString)
                if fileUrl != nil && image != nil {
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

                    // Save client image
                    if imageGenerationRequest.clientImage != nil {
                        let _: URL? = saveImageToDocumentsDirectory(
                            imageData: Data(base64Encoded: imageGenerationRequest.clientImage!)!,
                            withName: ".\(uuid)_client"
                        )
                        toPlatformImage(base64: imageGenerationRequest.clientImage!)?.saveToiCloud(fileName: ".\(uuid)_client")
                    }

                    // Save client mask
                    if imageGenerationRequest.clientMask != nil {
                        let _: URL? = saveImageToDocumentsDirectory(
                            imageData: Data(base64Encoded: imageGenerationRequest.clientMask!)!,
                            withName: ".\(uuid)_mask"
                        )
                        toPlatformImage(base64: imageGenerationRequest.clientMask!)?.saveToiCloud(fileName: ".\(uuid)_mask")
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
                    return ImageGenerationResponse(
                        status: EnumGenerationStatus.FAILED,
                        errorCode: EnumGenerateImageAdapterErrorCode.GENERATOR_ERROR,
                        errorMessage: "Could not save image"
                    )
                }
            } else {
                return ImageGenerationResponse(
                    status: EnumGenerationStatus.FAILED,
                    errorCode: EnumGenerateImageAdapterErrorCode.GENERATOR_ERROR,
                    errorMessage: "Could not decode base64"
                )
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
                for _ in 0 ..< imageGenerationRequest.numberOfImages {
                    group.addTask {
                        await self.atomicRequest(
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

            if imageGenerationResponses.isEmpty {
                return ImageSetResponse(
                    status: EnumGenerationStatus.FAILED,
                    errorCode: EnumGenerateImageAdapterErrorCode.GENERATOR_ERROR,
                    errorMessage: "No generation was successful"
                )
            }

            for generation in imageGenerationResponses {
                if generation.status == EnumGenerationStatus.FAILED || generation.generationId == nil {
                    return ImageSetResponse(
                        status: EnumGenerationStatus.FAILED,
                        errorCode: generation.errorCode ?? EnumGenerateImageAdapterErrorCode.GENERATOR_ERROR,
                        errorMessage: generation.errorMessage ?? "Failed with unknown error"
                    )
                }
            }

            let usedModel = connectionModels.first(where: { $0.modelId.uuidString == imageGenerationRequest.modelId })

            let set: ImageSet = .init(
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
                return generation
            }

            try? modelContext.save()

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
