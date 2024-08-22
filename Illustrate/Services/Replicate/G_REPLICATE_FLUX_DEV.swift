import Foundation

class G_REPLICATE_FLUX_DEV: ImageGenerationProtocol {
    func getCreditsUsed(request: ImageGenerationRequest) -> Double {
        return 0.03;
    }

    let model: PartnerModel = partnerModels.first(where: { $0.modelCode == EnumPartnerModelCode.REPLICATE_FLUX_DEV })!

    struct ServiceRequest: Codable {
        let prompt: String
        let num_outputs: Int
        let aspect_ratio: String
        let output_quality: Int
        let output_format: String?
        
        init(prompt: String, aspectRatio: String) {
            self.prompt = prompt
            self.num_outputs = 1
            self.aspect_ratio = aspectRatio
            self.output_quality = 100
            self.output_format = "png"
        }
    }

    func transformRequest(request: ImageGenerationRequest) -> ServiceRequest {
        let aspectRatio = getAspectRatio(dimension: request.artDimensions)

        return ServiceRequest(
            prompt: "\(request.artVariant.rawValue) - \(request.prompt)",
            aspectRatio: aspectRatio.ratio
        )
    }

    func transformResponse(request: ImageGenerationRequest, response: NetworkResponseData) throws -> ImageGenerationResponse {
        switch response {
        case .dictionary(_, let data):
            if let output = data["output"] as? [String],
               let pngUrl = output.first {
                    let url = URL(string: pngUrl)!
                    let pngData = try Data(contentsOf: url)
                    let base64 = pngData.base64EncodedString()
                
                    return ImageGenerationResponse(
                        status: .GENERATED,
                        base64: base64,
                        cost: getCreditsUsed(request: request)
                    )
                }
            if let pngUrl = data["output"] as? String {
                let url = URL(string: pngUrl)!
                let pngData = try Data(contentsOf: url)
                let base64 = pngData.base64EncodedString()
            
                return ImageGenerationResponse(
                    status: .GENERATED,
                    base64: base64,
                    cost: getCreditsUsed(request: request)
                )
            }
            if let errorList = data["error"] as? [String],
               let error = errorList.first {
                    return ImageGenerationResponse(
                        status: .FAILED,
                        errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                        errorMessage: error
                    )
                }
            if let error = data["error"] as? String {
                    return ImageGenerationResponse(
                        status: .FAILED,
                        errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                        errorMessage: error
                    )
                }
            break;
        case .array(_, _):
            return ImageGenerationResponse(
                status: .FAILED,
                errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Invalid response"
            )
        }
        
        print("Invalid response: \(response)")
        throw NSError(domain: "Invalid response", code: -1, userInfo: nil)
    }
    
    func pollForResult(requestId: String, url: URL, headers: [String: String], maxAttempts: Int = 10) async throws -> NetworkResponseData {
        var attempts = 0
        while attempts < maxAttempts {
            print("Polling for result \(requestId) - attempt \(attempts)/\(maxAttempts)...")
            try await Task.sleep(nanoseconds: 4_000_000_000)
            
            do {
                let response = try await NetworkAdapter.shared.performRequest(
                    url: url.appendingPathComponent("/\(requestId)"),
                    method: "GET",
                    body: nil as String?,
                    headers: headers
                )
                                                
                switch response {
                case .dictionary(_, let data):
                    if let status = data["status"] as? String,
                       status == "succeeded" || status == "failed" || status == "canceled" {
                            return response
                        }
                    break;
                case .array(_, _):
                    break;
                }
            } catch {
                throw NSError(domain: "Polling failed", code: -1, userInfo: nil)
            }
            
            attempts += 1
        }
        
        throw NSError(domain: "Polling exceeded max attempts", code: -1, userInfo: nil)
    }

    func makeRequest(request: ImageGenerationRequest) async throws -> ImageGenerationResponse {
        guard let url = URL(string: model.modelGenerateBaseURL) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }

        let transformedRequest = transformRequest(request: request)

        do {
            let headers: [String: String] = [
                "Authorization": "Bearer \(request.partnerKey.value)",
                "Content-Type": "application/json"
            ]
            
            let initialResponse = try await NetworkAdapter.shared.performRequest(
                url: url,
                method: "POST",
                body: [
                    "input": transformedRequest
                ],
                headers: headers
            )

            do {
                var requestId: String? = nil
                switch initialResponse {
                case .dictionary(_, let data):
                    if data["id"] as? String != nil {
                        requestId = data["id"] as? String
                    }
                case .array(_, _):
                    return ImageGenerationResponse(
                        status: .FAILED,
                        errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                        errorMessage: "Unexpected response"
                    )
                }
                
                guard let requestId = requestId else {
                    throw NSError(domain: "Failed to initiate request", code: -1, userInfo: nil)
                }
                
                guard let statusUrl = URL(string: model.modelStatusBaseURL!) else {
                    throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
                }

                let finalResponse = try await pollForResult(requestId: requestId, url: statusUrl, headers: headers)
                
                return try transformResponse(request: request, response: finalResponse)
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
