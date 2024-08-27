import Foundation

class G_REPLICATE_FLUX_SCHNELL: ImageGenerationProtocol {
    func getCreditsUsed(request _: ImageGenerationRequest) -> Double {
        return 0.0028
    }

    let model: ConnectionModel = connectionModels.first(where: { $0.modelCode == EnumConnectionModelCode.REPLICATE_FLUX_SCHNELL })!

    struct ServiceRequest: Codable {
        let prompt: String
        let num_outputs: Int
        let aspect_ratio: String
        let output_quality: Int
        let output_format: String?

        init(prompt: String, aspectRatio: String) {
            self.prompt = prompt
            num_outputs = 1
            aspect_ratio = aspectRatio
            output_quality = 100
            output_format = "png"
        }
    }

    func transformRequest(request: ImageGenerationRequest) -> ServiceRequest {
        let aspectRatio = getAspectRatio(dimension: request.artDimensions)

        return ServiceRequest(
            prompt: request.artVariant != EnumArtVariant.NORMAL ? "\(request.artVariant.rawValue) - \(request.prompt)" : request.prompt,
            aspectRatio: aspectRatio.ratio
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
                "Authorization": "Bearer \(request.connectionSecret)",
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
