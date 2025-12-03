import Foundation

class G_REPLICATE_SEEDREAM_3: ImageGenerationProtocol {
    func getCreditsUsed(request: ImageGenerationRequest) -> Double {
        return CostEstimator.getCreditsUsed(request: request)
    }

    let model: ProviderModel = ProviderService.shared.model(by: EnumProviderModelCode.REPLICATE_SEEDREAM_3.modelId.uuidString)!

    struct ServiceRequest: Codable {
        let prompt: String
        let aspect_ratio: String
        let size: String
        let guidance_scale: Double

        init(prompt: String, aspectRatio: String, size: String = "regular", guidanceScale: Double = 2.5) {
            self.prompt = prompt
            self.aspect_ratio = aspectRatio
            self.size = size
            self.guidance_scale = guidanceScale
        }
    }

    private func mapToSeedreamAspectRatio(dimension: String) -> String {
        let aspectRatio = getAspectRatio(dimension: dimension)
        let ratio = aspectRatio.ratio
        
        let supportedRatios = ["1:1", "3:4", "4:3", "16:9", "9:16", "2:3", "3:2", "21:9"]
        
        if supportedRatios.contains(ratio) {
            return ratio
        }
        
        let width = aspectRatio.width
        let height = aspectRatio.height
        let aspectValue = Double(width) / Double(height)
        
        let ratioValues: [(String, Double)] = [
            ("1:1", 1.0),
            ("3:4", 0.75),
            ("4:3", 1.333),
            ("16:9", 1.778),
            ("9:16", 0.5625),
            ("2:3", 0.667),
            ("3:2", 1.5),
            ("21:9", 2.333)
        ]
        
        var closestRatio = "16:9"
        var minDiff = Double.greatestFiniteMagnitude
        
        for (ratioStr, ratioVal) in ratioValues {
            let diff = abs(aspectValue - ratioVal)
            if diff < minDiff {
                minDiff = diff
                closestRatio = ratioStr
            }
        }
        
        return closestRatio
    }

    func transformRequest(request: ImageGenerationRequest) -> ServiceRequest {
        let aspectRatio = mapToSeedreamAspectRatio(dimension: request.artDimensions)

        return ServiceRequest(
            prompt: request.artVariant != EnumArtVariant.NORMAL ? "\(request.artVariant.rawValue) - \(request.prompt)" : request.prompt,
            aspectRatio: aspectRatio
        )
    }

    func transformResponse(request: ImageGenerationRequest, response: NetworkResponseData) throws -> ImageGenerationResponse {
        switch response {
        case let .dictionary(_, data):
            if let output = data["output"] as? [String],
               let pngUrl = output.first
            {
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
               let error = errorList.first
            {
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
        default:
            return ImageGenerationResponse(
                status: .FAILED,
                errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Invalid response"
            )
        }

        return ImageGenerationResponse(
            status: .FAILED,
            errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
            errorMessage: "Invalid response"
        )
    }

    func pollForResult(requestId: String, url: URL, headers: [String: String], maxAttempts: Int = 15) async throws -> NetworkResponseData {
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
                case let .dictionary(_, data):
                    if let status = data["status"] as? String,
                       status == "succeeded" || status == "failed" || status == "canceled"
                    {
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

    func makeRequest(request: ImageGenerationRequest) async throws -> ImageGenerationResponse {
        guard let url = URL(string: model.modelGenerateBaseURL) else {
            return ImageGenerationResponse(
                status: .FAILED,
                errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Invalid URL"
            )
        }

        let transformedRequest = transformRequest(request: request)

        do {
            let headers: [String: String] = [
                "Authorization": "Bearer \(request.providerSecret)",
                "Content-Type": "application/json",
            ]

            let initialResponse = try await NetworkAdapter.shared.performRequest(
                url: url,
                method: "POST",
                body: [
                    "input": transformedRequest,
                ],
                headers: headers
            )

            do {
                var requestId: String? = nil
                switch initialResponse {
                case let .dictionary(_, data):
                    if data["id"] as? String != nil {
                        requestId = data["id"] as? String
                    }
                default:
                    return ImageGenerationResponse(
                        status: .FAILED,
                        errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                        errorMessage: "Unexpected response"
                    )
                }

                guard let requestId = requestId else {
                    return ImageGenerationResponse(
                        status: .FAILED,
                        errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                        errorMessage: "Failed to initiate request"
                    )
                }

                guard let statusUrl = URL(string: model.modelStatusBaseURL!) else {
                    return ImageGenerationResponse(
                        status: .FAILED,
                        errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
                        errorMessage: "Invalid URL for status check"
                    )
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

