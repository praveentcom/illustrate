import Foundation

class G_STABILITY_ULTRA: ImageGenerationProtocol {
    func getCreditsUsed(request _: ImageGenerationRequest) -> Double {
        return 8.0
    }

    let model: ConnectionModel = connectionModels.first(where: { $0.modelCode == EnumConnectionModelCode.STABILITY_ULTRA })!

    struct ServiceRequest: Codable {
        let prompt: String
        let aspect_ratio: String
        let style_preset: String?
        let negative_prompt: String?
        let user: String

        init(prompt: String, aspectRatio: String, stylePreset: String?, negativePrompt: String?) {
            self.prompt = prompt
            aspect_ratio = aspectRatio
            style_preset = stylePreset
            negative_prompt = negativePrompt
            user = "illustrate_user"
        }
    }

    func mapArtVariantToModelStyle(artVariant: EnumArtVariant) -> String {
        switch artVariant {
        case .PIXEL_ART:
            return "pixel-art"
        case .ANIME:
            return "anime"
        case .COMIC_BOOK:
            return "comic-book"
        case .FANTASY_ART:
            return "fantasy-art"
        case .LINE_ART, .ABSTRACT, .INK:
            return "line-art"
        case .DIGITAL_ART:
            return "digital-art"
        case .ANALOG_FILM:
            return "analog-film"
        case .NEON_PUNK:
            return "neon-punk"
        case .ISOMETRIC:
            return "isometric"
        case .ORIGAMI:
            return "origami"
        case .MODEL_3D:
            return "3d-model"
        case .CINEMATIC:
            return "cinematic"
        case .TILE_TEXTURE:
            return "tile-texture"
        default:
            return "photographic"
        }
    }

    func getImageDimensions(artDimensions: String) -> String {
        switch artDimensions {
        case "576x1024":
            return "9:16"
        case "1024x576":
            return "16:9"
        case "768x1024":
            return "3:4"
        case "1024x768":
            return "4:3"
        case "1024x1024":
            return "1:1"
        default:
            return "1:1"
        }
    }

    func transformRequest(request: ImageGenerationRequest) -> ServiceRequest {
        let stylePreset = mapArtVariantToModelStyle(artVariant: request.artVariant)
        let aspectRatio = getImageDimensions(artDimensions: request.artDimensions)

        return ServiceRequest(
            prompt: request.prompt,
            aspectRatio: aspectRatio,
            stylePreset: stylePreset,
            negativePrompt: request.negativePrompt
        )
    }

    func transformResponse(request: ImageGenerationRequest, response: NetworkResponseData) throws -> ImageGenerationResponse {
        switch response {
        case let .dictionary(_, data):
            if let imageData = data["image"] as? String {
                return ImageGenerationResponse(
                    status: .GENERATED,
                    base64: imageData,
                    cost: getCreditsUsed(request: request),
                    modelPrompt: request.prompt
                )
            } else if let errors = data["errors"] as? [String],
                      let message = errors.first
            {
                return ImageGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                    errorMessage: message
                )
            } else if let message = data["message"] as? String {
                return ImageGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                    errorMessage: message
                )
            }
        case let .array(_, data):
            if let firstDict = data.first,
               let imageData = firstDict["image"] as? String
            {
                return ImageGenerationResponse(
                    status: .GENERATED,
                    base64: imageData,
                    cost: getCreditsUsed(request: request),
                    modelPrompt: request.prompt
                )
            } else if let errors = data.first?["errors"] as? [String],
                      let message = errors.first
            {
                return ImageGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                    errorMessage: message
                )
            } else if let message = data.first?["message"] as? String {
                return ImageGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                    errorMessage: message
                )
            }
        default:
            return ImageGenerationResponse(
                status: .FAILED,
                errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Unexpected response"
            )
        }

        return ImageGenerationResponse(
            status: .FAILED,
            errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
            errorMessage: "Invalid response"
        )
    }

    func makeRequest(request: ImageGenerationRequest) async throws -> ImageGenerationResponse {
        guard let url = URL(string: model.modelGenerateBaseURL) else {
            return ImageGenerationResponse(
                status: .FAILED,
                errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Invalid URL"
            )
        }

        let transformedRequest = transformRequest(request: request)

        do {
            let generation = try await NetworkAdapter.shared.performRequest(
                url: url,
                method: "POST",
                body: transformedRequest,
                headers: [
                    "Authorization": "\(request.connectionSecret)",
                    "Content-Type": "multipart/form-data",
                    "Accept": "application/json",
                ]
            )

            do {
                return try transformResponse(request: request, response: generation)
            } catch {
                return ImageGenerationResponse(
                    status: EnumGenerationStatus.FAILED,
                    errorCode: EnumGenerateImageAdapterErrorCode.TRANSFORM_RESPONSE_ERROR,
                    errorMessage: "Failed with error: \(error)"
                )
            }
        } catch {
            return ImageGenerationResponse(
                status: EnumGenerationStatus.FAILED,
                errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Failed with error: \(error)"
            )
        }
    }
}
