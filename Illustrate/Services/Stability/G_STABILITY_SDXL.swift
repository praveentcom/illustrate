import Foundation

class G_STABILITY_SDXL: ImageGenerationProtocol {
    func getCreditsUsed(request: ImageGenerationRequest) -> Double {
        return 0.2
    }

    let model: PartnerModel = partnerModels.first(where: { $0.modelCode == EnumPartnerModelCode.STABILITY_SDXL })!

    struct ServiceRequest: Codable {
        let text_prompts: [TextPrompt]
        let cfg_scale: Double
        let width: Int
        let height: Int
        let steps: Int
        let samples: Int
        let user: String

        struct TextPrompt: Codable {
            let text: String
        }

        init(prompt: String, width: Int, height: Int) {
            self.text_prompts = [TextPrompt(text: prompt)]
            self.cfg_scale = 7.0
            self.width = width
            self.height = height
            self.steps = 30
            self.samples = 1
            self.user = "illustrate_user"
        }
    }

    func getImageDimensions(artDimensions: String) -> (width: Int, height: Int) {
        switch artDimensions {
        case "1152x896":
            return (1152, 896)
        case "896x1152":
            return (896, 1152)
        case "1216x832":
            return (1216, 832)
        case "1344x768":
            return (1344, 768)
        case "768x1344":
            return (768, 1344)
        case "1536x640":
            return (1536, 640)
        case "640x1536":
            return (640, 1536)
        case "1024x1024":
            return (1024, 1024)
        default:
            return (1024, 1024)
        }
    }

    func transformRequest(request: ImageGenerationRequest) -> ServiceRequest {
        let dimensions = getImageDimensions(artDimensions: request.artDimensions)
        return ServiceRequest(
            prompt: request.prompt,
            width: dimensions.width,
            height: dimensions.height
        )
    }

    func transformResponse(request: ImageGenerationRequest, response: NetworkResponseData) throws -> ImageGenerationResponse {
        switch response {
        case .dictionary(_, let data):
            if let artifacts = data["artifacts"] as? [[String: Any]],
               let firstArtifact = artifacts.first,
               let base64String = firstArtifact["base64"] as? String {
                return ImageGenerationResponse(
                    status: .GENERATED,
                    base64: base64String,
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
               let artifacts = firstDict["artifacts"] as? [[String: Any]],
               let base64String = artifacts.first?["base64"] as? String {
                return ImageGenerationResponse(
                    status: .GENERATED,
                    base64: base64String,
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
                    "Authorization": "\(request.partnerKey.value)",
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
