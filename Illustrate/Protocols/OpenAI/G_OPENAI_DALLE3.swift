import Foundation

class G_OPENAI_DALLE3: ImageGenerationProtocol {
    func getCreditsUsed(request: ImageGenerationRequest) -> Double {
        return CostEstimator.getCreditsUsed(request: request)
    }

    let model: ConnectionModel = ConnectionService.shared.model(by: EnumConnectionModelCode.OPENAI_DALLE3.modelId.uuidString)!

    struct ServiceRequest: Codable {
        let model: String
        let prompt: String
        let n: Int
        let size: String
        let quality: String
        let style: String?
        let response_format: String?
        let user: String

        init(prompt: String, aspectRatio: String, artQuality: String, stylePreset: String) {
            model = "dall-e-3"
            self.prompt = prompt
            n = 1
            size = aspectRatio
            quality = artQuality
            style = stylePreset
            response_format = "b64_json"
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
        case "1792x1024":
            return "1792x1024"
        case "1024x1792":
            return "1024x1792"
        case "1024x1024":
            return "1024x1024"
        default:
            return "1024x1024"
        }
    }

    func transformRequest(request: ImageGenerationRequest) -> ServiceRequest {
        let stylePreset = mapArtVariantToModelStyle(artVariant: request.artVariant)
        let aspectRatio = getImageDimensions(artDimensions: request.artDimensions)

        return ServiceRequest(
            prompt: "\(stylePreset) - \(request.prompt)",
            aspectRatio: aspectRatio,
            artQuality: request.artQuality.rawValue.lowercased(),
            stylePreset: request.artStyle.rawValue.lowercased()
        )
    }

    func transformResponse(request: ImageGenerationRequest, response: NetworkResponseData) throws -> ImageGenerationResponse {
        switch response {
        case let .dictionary(_, data):
            if let nestedData = data["data"] as? [[String: Any]],
               let imageData = nestedData.first?["b64_json"] as? String
            {
                return ImageGenerationResponse(
                    status: .GENERATED,
                    base64: imageData,
                    cost: getCreditsUsed(request: request),
                    modelPrompt: nestedData.first?["revised_prompt"] as? String? ?? request.prompt
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
            } else if let error = data["error"] as? [String: Any],
                      let message = error["message"] as? String
            {
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

        print(response)

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
                    "Authorization": "Bearer \(request.connectionSecret)",
                    "Content-Type": "application/json",
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
