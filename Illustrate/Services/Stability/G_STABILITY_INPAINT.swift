import Foundation

class G_STABILITY_INPAINT: ImageGenerationProtocol {
    func getCreditsUsed(request _: ImageGenerationRequest) -> Double {
        return 3.0
    }

    let model: ConnectionModel = connectionModels.first(where: { $0.modelCode == EnumConnectionModelCode.STABILITY_INPAINT })!

    struct ServiceRequest: Codable {
        let prompt: String
        let negative_prompt: String?
        let user: String

        init(prompt: String, negativePrompt: String?, editDirection _: ImageEditDirection?) {
            self.prompt = prompt
            negative_prompt = negativePrompt
            user = "illustrate_user"
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
        guard request.clientMask != nil else {
            return ImageGenerationResponse(
                status: .FAILED,
                errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Draw the mask area on the image"
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
                NetworkRequestAttachment(
                    name: "mask",
                    mimeType: "png",
                    data: Data(
                        base64Encoded: request.clientMask!.replacingOccurrences(
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
