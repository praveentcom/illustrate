import Foundation

class G_STABILITY_IMAGE_TO_VIDEO: VideoGenerationProtocol {
    func getCreditsUsed(request: VideoGenerationRequest) -> Double {
        return 20.0
    }
    
    let model: PartnerModel = partnerModels.first(where: { $0.modelCode == EnumPartnerModelCode.STABILITY_IMAGE_TO_VIDEO })!
    
    struct ServiceRequest: Codable {
        let prompt: String?
        let negative_prompt: String?
        let cfg_scale: Int?
        let motion_bucket_id: Int?
        let user: String
        
        init(prompt: String?, negativePrompt: String?, motion: Int?, stickyness: Int?) {
            self.prompt = prompt
            self.negative_prompt = negativePrompt
            self.cfg_scale = stickyness
            self.motion_bucket_id = motion
            self.user = "illustrate_user"
        }
    }
    
    func transformRequest(request: VideoGenerationRequest) -> ServiceRequest {
        return ServiceRequest(
            prompt: request.prompt,
            negativePrompt: request.negativePrompt,
            motion: request.motion,
            stickyness: request.stickyness
        )
    }
    
    func pollForResult(requestId: String, url: URL, headers: [String: String], maxAttempts: Int = 10) async throws -> NetworkResponseData {
        var attempts = 0
        while attempts < maxAttempts {
            print("Polling for result \(requestId) - attempt \(attempts)/\(maxAttempts)...")
            try await Task.sleep(nanoseconds: 10_000_000_000)
            
            do {
                let response = try await NetworkAdapter.shared.performRequest(
                    url: url.appendingPathComponent("/result/\(requestId)"),
                    method: "GET",
                    body: nil as String?,
                    headers: headers
                )
                                
                switch response {
                case .dictionary(let statusCode, _):
                    if statusCode == 200 {
                        return response
                    }
                case .array(let statusCode, _):
                    if statusCode == 200 {
                        return response
                    }
                }
            } catch {
                throw NSError(domain: "Polling failed", code: -1, userInfo: nil)
            }
            
            attempts += 1
        }
        
        throw NSError(domain: "Polling exceeded max attempts", code: -1, userInfo: nil)
    }
    
    func transformResponse(request: VideoGenerationRequest, response: NetworkResponseData) throws -> VideoGenerationResponse {
        switch response {
        case .dictionary(_, let data):
            if let videoData = data["video"] as? String {
                return VideoGenerationResponse(
                    status: .GENERATED,
                    base64: videoData,
                    cost: getCreditsUsed(request: request),
                    modelPrompt: request.prompt
                )
            }
            else if let errors = data["errors"] as? [String],
                    let message = errors.first {
                return VideoGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                    errorMessage: message
                )
            }
            else if let message = data["message"] as? String {
                return VideoGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                    errorMessage: message
                )
            }
        default:
            throw NSError(domain: "Invalid response format", code: -1, userInfo: nil)
        }
        
        throw NSError(domain: "Invalid response", code: -1, userInfo: nil)
    }
    
    func makeRequest(request: VideoGenerationRequest) async throws -> VideoGenerationResponse {
        guard let url = URL(string: model.modelGenerateBaseURL) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }
        
        let transformedRequest = transformRequest(request: request)
        
        let headers: [String: String] = [
            "Authorization": "\(request.partnerKey.value)",
            "Content-Type": "multipart/form-data",
            "Accept": "application/json"
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
                )
            ]
        )
                
        var requestId: String? = nil
        switch initialResponse {
        case .dictionary(_, let data):
            if let errors = data["errors"] as? [String],
                let message = errors.first {
                return VideoGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                    errorMessage: message
                )
            }
            else if data["id"] as? String != nil {
                requestId = data["id"] as? String
            }
        case .array(_, let data):
            if let errors = data[0]["errors"] as? [String],
                let message = errors.first {
                return VideoGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                    errorMessage: message
                )
            }
            else if data[0]["id"] as? String != nil {
                requestId = data[0]["id"] as? String
            }
        }
        
        guard let requestId = requestId else {
            throw NSError(domain: "Failed to initiate request", code: -1, userInfo: nil)
        }
        
        let finalResponse = try await pollForResult(requestId: requestId, url: url, headers: headers)
        
        return try transformResponse(request: request, response: finalResponse)
    }
}
