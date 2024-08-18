import Foundation

class G_STABILITY_SEARCH_AND_REPLACE: ImageGenerationProtocol {
    func getCreditsUsed(request: ImageGenerationRequest) -> Double {
        return 4.0
    }
    
    let model: PartnerModel = partnerModels.first(where: { $0.modelCode == EnumPartnerModelCode.STABILITY_SEARCH_AND_REPLACE })!
    
    struct ServiceRequest: Codable {
        let prompt: String
        let negative_prompt: String?
        let search_prompt: String
        let user: String
        
        init(prompt: String, searchPrompt: String, negativePrompt: String?) {
            self.prompt = prompt
            self.search_prompt = searchPrompt
            self.negative_prompt = negativePrompt
            self.user = "illustrate_user"
        }
    }
    
    func transformRequest(request: ImageGenerationRequest) -> ServiceRequest {
        return ServiceRequest(
            prompt: request.prompt,
            searchPrompt: request.searchPrompt ?? "",
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
        default:
            throw NSError(domain: "Invalid response format", code: -1, userInfo: nil)
        }
        
        throw NSError(domain: "Invalid response", code: -1, userInfo: nil)
    }
    
    func makeRequest(request: ImageGenerationRequest) async throws -> ImageGenerationResponse {
        guard let url = URL(string: model.modelGenerateBaseURL) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        
        let transformedRequest = transformRequest(request: request)
        
        let headers: [String: String] = [
            "Authorization": "\(request.partnerKey.value)",
            "Content-Type": "multipart/form-data",
            "Accept": "application/json"
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
                )
            ]
        )
        
        return try transformResponse(request: request, response: response)
    }
}
