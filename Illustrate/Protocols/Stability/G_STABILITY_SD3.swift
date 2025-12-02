import Foundation

class G_STABILITY_SD3: ImageGenerationProtocol {
    func getCreditsUsed(request: ImageGenerationRequest) -> Double {
        return CostEstimator.getCreditsUsed(request: request)
    }

    let model: ConnectionModel = ConnectionService.shared.model(by: EnumConnectionModelCode.STABILITY_SD3.modelId.uuidString)!

    struct ServiceRequest: Codable {
        let prompt: String
        let model: String
        let aspect_ratio: String
        let negative_prompt: String?
        let user: String

        init(prompt: String, model: String, aspectRatio: String, negativePrompt: String?) {
            self.prompt = prompt
            self.model = model
            aspect_ratio = aspectRatio
            negative_prompt = negativePrompt
            user = "illustrate_user"
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
        let aspectRatio = getImageDimensions(artDimensions: request.artDimensions)

        let model = ConnectionService.shared.model(by: request.modelId)
        let modelString: String

        switch model?.modelCode {
        case .STABILITY_SD3_TURBO:
            modelString = "sd3-turbo"
        case .STABILITY_SD3:
            modelString = "sd3"
        case .STABILITY_SD35_LARGE:
            modelString = "sd3.5-large"
        case .STABILITY_SD35_LARGE_TURBO:
            modelString = "sd3.5-large-turbo"
        case .STABILITY_SD35_MEDIUM:
            modelString = "sd3.5-medium"
        case .STABILITY_SD35_FLASH:
            modelString = "sd3.5-flash"
        default:
            modelString = "sd3"
        }

        return ServiceRequest(
            prompt: request.prompt,
            model: modelString,
            aspectRatio: aspectRatio,
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
