import Foundation

class G_STABILITY_SD3: ImageGenerationProtocol {
    func getCreditsUsed(request: ImageGenerationRequest) -> Double {
        let model = connectionModels.first(where: { $0.modelId.uuidString == request.modelId })
        
        switch model?.modelCode {
        case .STABILITY_SD3_TURBO:
            return 4.0
        case .STABILITY_SD3:
            return 6.5
        default:
            return 6.5
        }
    }

    let model: ConnectionModel = connectionModels.first(where: { $0.modelCode == EnumConnectionModelCode.STABILITY_SD3 })!

    struct ServiceRequest: Codable {
        let prompt: String
        let model: String
        let aspect_ratio: String
        let negative_prompt: String?
        let user: String
        
        init(prompt: String, model: String, aspectRatio: String, negativePrompt: String?) {
            self.prompt = prompt
            self.model = model
            self.aspect_ratio = aspectRatio
            self.negative_prompt = negativePrompt
            self.user = "illustrate_user"
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
        
        let model = connectionModels.first(where: { $0.modelId.uuidString == request.modelId })
        let modelString = model?.modelCode == .STABILITY_SD3_TURBO ? "sd3-turbo" : "sd3"

        return ServiceRequest(
            prompt: request.prompt,
            model: modelString,
            aspectRatio: aspectRatio,
            negativePrompt: request.negativePrompt
        )
    }

    func transformResponse(request: ImageGenerationRequest, response: NetworkResponseData) throws -> ImageGenerationResponse {        
        switch response {
        case .dictionary(_, let data):
            if let imageData = data["image"] as? String {
                return ImageGenerationResponse(
                    status: .GENERATED,
                    base64: imageData,
                    cost: getCreditsUsed(request: request),
                    modelPrompt: request.prompt
                )
            }
            else if let errors = data["errors"] as? [String],
                let message = errors.first {
                return ImageGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                    errorMessage: message
                )
            }
            else if let message = data["message"] as? String {
                return ImageGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                    errorMessage: message
                )
            }
        case .array(_, let data):
            if let firstDict = data.first,
               let imageData = firstDict["image"] as? String {
                return ImageGenerationResponse(
                    status: .GENERATED,
                    base64: imageData,
                    cost: getCreditsUsed(request: request),
                    modelPrompt: request.prompt
                )
            }
            else if let errors = data.first?["errors"] as? [String],
                let message = errors.first {
                return ImageGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                    errorMessage: message
                )
            }
            else if let message = data.first?["message"] as? String {
                return ImageGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                    errorMessage: message
                )
            }
        }

        throw NSError(domain: "Invalid response", code: -1, userInfo: nil)
    }

    func makeRequest(request: ImageGenerationRequest) async throws -> ImageGenerationResponse {
        guard let url = URL(string: model.modelGenerateBaseURL) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
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
                    "Accept": "application/json"
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
