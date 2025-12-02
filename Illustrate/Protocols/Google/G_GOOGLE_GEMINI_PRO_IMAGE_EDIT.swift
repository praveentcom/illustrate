import Foundation

class G_GOOGLE_GEMINI_PRO_IMAGE_EDIT: ImageGenerationProtocol {
    func getCreditsUsed(request: ImageGenerationRequest) -> Double {
        return CostEstimator.getCreditsUsed(request: request)
    }

    let model: ConnectionModel = ConnectionService.shared.model(by: EnumConnectionModelCode.GOOGLE_GEMINI_PRO_IMAGE_EDIT.modelId.uuidString)!

    struct ContentPart: Codable {
        var text: String?
        var inlineData: InlineData?

        struct InlineData: Codable {
            var mimeType: String
            var data: String
        }
    }

    struct Content: Codable {
        var parts: [ContentPart]
    }

    struct ImageConfig: Codable {
        var aspectRatio: String?
        var imageSize: String?
    }

    struct GenerationConfig: Codable {
        var responseModalities: [String]?
        var imageConfig: ImageConfig?
    }

    struct ServiceRequest: Codable {
        var contents: [Content]
        var generationConfig: GenerationConfig?

        init(prompt: String, imageBase64: String, mimeType: String = "image/png", aspectRatio: String?, artQuality: EnumArtQuality, modalities: [String]?) {
            self.contents = [
                Content(parts: [
                    ContentPart(text: prompt, inlineData: nil),
                    ContentPart(text: nil, inlineData: ContentPart.InlineData(mimeType: mimeType, data: imageBase64))
                ])
            ]
            
            var imageConfig: ImageConfig? = nil
            imageConfig = ImageConfig(
                aspectRatio: aspectRatio,
                imageSize: artQuality == .HD ? "4K" : "2K"
            )
            
            self.generationConfig = GenerationConfig(
                responseModalities: modalities,
                imageConfig: imageConfig
            )
        }
    }

    func transformRequest(request: ImageGenerationRequest) -> ServiceRequest {
        let imageBase64 = request.clientImage?.replacingOccurrences(
            of: "^data:.*;base64,",
            with: "",
            options: .regularExpression
        ) ?? ""

        let aspectRatio = convertToAspectRatio(request.artDimensions)
        
        let modalities: [String]? = request.responseModalities.isEmpty ? nil : request.responseModalities.map { $0.rawValue }
        
        return ServiceRequest(prompt: request.prompt, imageBase64: imageBase64, aspectRatio: aspectRatio, artQuality: request.artQuality, modalities: modalities)
    }

    private func convertToAspectRatio(_ dimensions: String) -> String? {
        if dimensions.contains(":") {
            return dimensions
        }
        return nil
    }

    func transformResponse(request: ImageGenerationRequest, response: NetworkResponseData) throws -> ImageGenerationResponse {
        switch response {
        case let .dictionary(_, data):
            if let candidates = data["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]]
            {
                for part in parts {
                    if let inlineData = part["inlineData"] as? [String: Any],
                       let imageData = inlineData["data"] as? String
                    {
                        return ImageGenerationResponse(
                            status: .GENERATED,
                            base64: imageData,
                            cost: getCreditsUsed(request: request),
                            modelPrompt: request.prompt
                        )
                    }
                }

                for part in parts {
                    if let text = part["text"] as? String {
                        return ImageGenerationResponse(
                            status: .FAILED,
                            errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                            errorMessage: "No image generated. Response: \(text)"
                        )
                    }
                }
            }

            if let error = data["error"] as? [String: Any],
               let message = error["message"] as? String
            {
                return ImageGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                    errorMessage: message
                )
            }

            if let promptFeedback = data["promptFeedback"] as? [String: Any],
               let blockReason = promptFeedback["blockReason"] as? String
            {
                return ImageGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                    errorMessage: "Prompt blocked: \(blockReason)"
                )
            }

        default:
            return ImageGenerationResponse(
                status: .FAILED,
                errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Unexpected response format"
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
                errorMessage: "Select an image to edit"
            )
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "key", value: request.connectionSecret)]

        guard let finalURL = components.url else {
            return ImageGenerationResponse(
                status: .FAILED,
                errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Failed to construct URL with API key"
            )
        }

        let transformedRequest = transformRequest(request: request)
        
        do {
            let generation = try await NetworkAdapter.shared.performRequest(
                url: finalURL,
                method: "POST",
                body: transformedRequest,
                headers: [
                    "Content-Type": "application/json"
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
