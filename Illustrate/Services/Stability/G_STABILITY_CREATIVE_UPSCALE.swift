import Foundation

class G_STABILITY_CREATIVE_UPSCALE: ImageGenerationProtocol {
    func getCreditsUsed(request _: ImageGenerationRequest) -> Double {
        return 25.0
    }

    let model: ConnectionModel = connectionModels.first(where: { $0.modelCode == EnumConnectionModelCode.STABILITY_CREATIVE_UPSCALE })!

    struct ServiceRequest: Codable {
        let prompt: String
        let negative_prompt: String?
        let user: String

        init(prompt: String, negativePrompt: String?) {
            self.prompt = prompt
            negative_prompt = negativePrompt
            user = "illustrate_user"
        }
    }

    func transformRequest(request: ImageGenerationRequest) -> ServiceRequest {
        return ServiceRequest(
            prompt: request.prompt,
            negativePrompt: request.negativePrompt
        )
    }

    func pollForResult(requestId: String, url: URL, headers: [String: String], maxAttempts: Int = 10) async throws -> NetworkResponseData {
        var attempts = 0
        while attempts < maxAttempts {
            print("Polling for result \(requestId) - attempt \(attempts)/\(maxAttempts)...")
            try await Task.sleep(nanoseconds: 8_000_000_000)

            do {
                let response = try await NetworkAdapter.shared.performRequest(
                    url: url.appendingPathComponent("/result/\(requestId)"),
                    method: "GET",
                    body: nil as String?,
                    headers: headers
                )

                switch response {
                case let .dictionary(statusCode, _):
                    if statusCode == 200 {
                        return response
                    }
                case let .array(statusCode, _):
                    if statusCode == 200 {
                        return response
                    }
                default:
                    break
                }
            } catch {
                throw NSError(domain: "Polling failed", code: -1, userInfo: nil)
            }

            attempts += 1
        }

        throw NSError(domain: "Polling exceeded max attempts", code: -1, userInfo: nil)
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

        let initialResponse = try await NetworkAdapter.shared.performRequest(
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

        var requestId: String? = nil
        switch initialResponse {
        case let .dictionary(_, data):
            if let errors = data["errors"] as? [String],
               let message = errors.first
            {
                return ImageGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                    errorMessage: message
                )
            } else if data["id"] as? String != nil {
                requestId = data["id"] as? String
            }
        case let .array(_, data):
            if let errors = data[0]["errors"] as? [String],
               let message = errors.first
            {
                return ImageGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                    errorMessage: message
                )
            } else if data[0]["id"] as? String != nil {
                requestId = data[0]["id"] as? String
            }
        default:
            return ImageGenerationResponse(
                status: .FAILED,
                errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Invalid response"
            )
        }

        guard let requestId = requestId else {
            return ImageGenerationResponse(
                status: .FAILED,
                errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Failed to initiate request"
            )
        }

        let finalResponse = try await pollForResult(requestId: requestId, url: url, headers: headers)

        return try transformResponse(request: request, response: finalResponse)
    }
}
