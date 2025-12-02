import Foundation

class G_STABILITY_OUTPAINT: ImageGenerationProtocol {
    func getCreditsUsed(request: ImageGenerationRequest) -> Double {
        return CostEstimator.getCreditsUsed(request: request)
    }

    let model: ConnectionModel = ConnectionService.shared.model(by: EnumConnectionModelCode.STABILITY_OUTPAINT.modelId.uuidString)!

    struct ServiceRequest: Codable {
        let prompt: String
        let negative_prompt: String?
        let user: String
        let left: Int
        let right: Int
        let up: Int
        let down: Int

        init(prompt: String, negativePrompt: String?, editDirection: ImageEditDirection?) {
            self.prompt = prompt
            negative_prompt = negativePrompt
            user = "illustrate_user"
            left = editDirection?.left ?? 0
            right = editDirection?.right ?? 0
            up = editDirection?.up ?? 0
            down = editDirection?.down ?? 0
        }
    }

    func transformRequest(request: ImageGenerationRequest) -> ServiceRequest {
        return ServiceRequest(
            prompt: request.prompt,
            negativePrompt: request.negativePrompt,
            editDirection: request.editDirection
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
        guard request.clientImage != nil else {
            return ImageGenerationResponse(
                status: .FAILED,
                errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Select an image"
            )
        }

        let transformedRequest = transformRequest(request: request)

        let headers: [String: String] = [
            "Authorization": "\(request.connectionSecret)",
            "Content-Type": "multipart/form-data",
            "Accept": "application/json",
        ]

        let response = try await NetworkAdapter.shared.performRequest(
            url: url,
            method: "POST",
            body: transformedRequest,
            headers: headers,
            attachments: [
                NetworkRequestAttachment(
                    name: "image",
                    mimeType: "png",
                    data: Data(
                        base64Encoded: request.clientImage!.replacingOccurrences(
                            of: "^data:.*;base64,",
                            with: "",
                            options: .regularExpression
                        )
                    )!
                ),
            ]
        )

        return try transformResponse(request: request, response: response)
    }
}
