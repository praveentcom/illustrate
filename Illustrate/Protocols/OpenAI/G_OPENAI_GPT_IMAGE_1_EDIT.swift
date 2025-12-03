import Foundation

class G_OPENAI_GPT_IMAGE_1_EDIT: ImageGenerationProtocol {
    func getCreditsUsed(request: ImageGenerationRequest) -> Double {
        return CostEstimator.getCreditsUsed(request: request)
    }

    let model: ConnectionModel = ConnectionService.shared.model(by: EnumConnectionModelCode.OPENAI_GPT_IMAGE_1_EDIT.modelId.uuidString)!

    struct ServiceRequest: Codable {
        let model: String
        let prompt: String
        let size: String
        let quality: String

        init(prompt: String, size: String, quality: String) {
            model = "gpt-image-1"
            self.prompt = prompt
            self.size = size
            self.quality = quality
        }
    }

    func mapQualityToAPIValue(artQuality: EnumArtQuality) -> String {
        switch artQuality {
        case .HD:
            return "high"
        case .STANDARD:
            return "medium"
        }
    }

    func getImageDimensions(artDimensions: String) -> String {
        switch artDimensions {
        case "1536x1024":
            return "1536x1024"
        case "1024x1536":
            return "1024x1536"
        case "1024x1024":
            return "1024x1024"
        default:
            return "1024x1024"
        }
    }

    func transformRequest(request: ImageGenerationRequest) -> ServiceRequest {
        let size = getImageDimensions(artDimensions: request.artDimensions)
        let quality = mapQualityToAPIValue(artQuality: request.artQuality)

        return ServiceRequest(
            prompt: request.prompt,
            size: size,
            quality: quality
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

        guard request.clientImage != nil else {
            return ImageGenerationResponse(
                status: .FAILED,
                errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Select an image"
            )
        }

        let transformedRequest = transformRequest(request: request)

        let headers: [String: String] = [
            "Authorization": "Bearer \(request.connectionSecret)",
            "Content-Type": "multipart/form-data",
            "Accept": "application/json",
        ]

        var attachments: [NetworkRequestAttachment] = [
            NetworkRequestAttachment(
                name: "image",
                mimeType: "image/png",
                data: Data(
                    base64Encoded: request.clientImage!.replacingOccurrences(
                        of: "^data:.*;base64,",
                        with: "",
                        options: .regularExpression
                    )
                )!
            )
        ]

        // Add mask if provided (optional for gpt-image-1)
        if let clientMask = request.clientMask {
            attachments.append(
                NetworkRequestAttachment(
                    name: "mask",
                    mimeType: "image/png",
                    data: Data(
                        base64Encoded: clientMask.replacingOccurrences(
                            of: "^data:.*;base64,",
                            with: "",
                            options: .regularExpression
                        )
                    )!
                )
            )
        }

        let response = try await NetworkAdapter.shared.performRequest(
            url: url,
            method: "POST",
            body: transformedRequest,
            headers: headers,
            attachments: attachments
        )

        return try transformResponse(request: request, response: response)
    }
}

