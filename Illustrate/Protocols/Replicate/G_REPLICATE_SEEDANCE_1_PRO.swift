import Foundation

class G_REPLICATE_SEEDANCE_1_PRO: VideoGenerationProtocol {
    func getCreditsUsed(request: VideoGenerationRequest) -> Double {
        return CostEstimator.getCreditsUsed(request: request)
    }

    let model: ConnectionModel = ConnectionService.shared.model(by: EnumConnectionModelCode.REPLICATE_SEEDANCE_1_PRO.modelId.uuidString)!

    struct ServiceRequest: Codable {
        let prompt: String
        let duration: Int
        let resolution: String
        let aspect_ratio: String
        let fps: Int
        let camera_fixed: Bool
        let image: String?
        let last_frame_image: String?

        init(
            prompt: String,
            duration: Int = 5,
            resolution: String = "1080p",
            aspectRatio: String = "16:9",
            fps: Int = 24,
            cameraFixed: Bool = false,
            image: String? = nil,
            lastFrameImage: String? = nil
        ) {
            self.prompt = prompt
            self.duration = duration
            self.resolution = resolution
            self.aspect_ratio = aspectRatio
            self.fps = fps
            self.camera_fixed = cameraFixed
            self.image = image
            self.last_frame_image = lastFrameImage
        }
    }

    private func mapToSeedanceAspectRatio(dimension: String) -> String {
        let aspectRatio = getAspectRatio(dimension: dimension)
        let ratio = aspectRatio.ratio
        
        let supportedRatios = ["16:9", "4:3", "1:1", "3:4", "9:16", "21:9", "9:21"]
        
        if supportedRatios.contains(ratio) {
            return ratio
        }
        
        let width = aspectRatio.width
        let height = aspectRatio.height
        let aspectValue = Double(width) / Double(height)
        
        let ratioValues: [(String, Double)] = [
            ("16:9", 1.778),
            ("4:3", 1.333),
            ("1:1", 1.0),
            ("3:4", 0.75),
            ("9:16", 0.5625),
            ("21:9", 2.333),
            ("9:21", 0.429)
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
    
    private func mapToResolution(_ dimensions: String) -> String {
        let parts = dimensions.lowercased().split(separator: "x")
        guard parts.count == 2,
              let width = Int(parts[0]),
              let height = Int(parts[1]) else {
            return "1080p"
        }
        
        let maxDim = max(width, height)
        if maxDim >= 1080 {
            return "1080p"
        } else if maxDim >= 720 {
            return "720p"
        }
        return "480p"
    }

    func transformRequest(request: VideoGenerationRequest) -> ServiceRequest {
        let aspectRatio = mapToSeedanceAspectRatio(dimension: request.artDimensions)
        let resolution = request.resolution ?? mapToResolution(request.artDimensions)
        let duration = request.durationSeconds ?? 5
        let fps = request.fps ?? 24
        
        return ServiceRequest(
            prompt: request.prompt ?? "",
            duration: duration,
            resolution: resolution,
            aspectRatio: aspectRatio,
            fps: fps,
            image: nil,
            lastFrameImage: nil
        )
    }

    func transformResponse(request: VideoGenerationRequest, response: NetworkResponseData) throws -> VideoGenerationResponse {
        switch response {
        case let .dictionary(_, data):
            if let output = data["output"] as? String {
                let url = URL(string: output)!
                let videoData = try Data(contentsOf: url)
                let base64 = videoData.base64EncodedString()

                return VideoGenerationResponse(
                    status: .GENERATED,
                    base64: base64,
                    cost: getCreditsUsed(request: request)
                )
            }
            if let errorList = data["error"] as? [String],
               let error = errorList.first
            {
                return VideoGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                    errorMessage: error
                )
            }
            if let error = data["error"] as? String {
                return VideoGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                    errorMessage: error
                )
            }
        default:
            return VideoGenerationResponse(
                status: .FAILED,
                errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Invalid response"
            )
        }

        return VideoGenerationResponse(
            status: .FAILED,
            errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
            errorMessage: "Invalid response"
        )
    }

    func pollForResult(requestId: String, url: URL, headers: [String: String], maxAttempts: Int = 60) async throws -> NetworkResponseData {
        var attempts = 0
        while attempts < maxAttempts {
            print("Polling for video result \(requestId) - attempt \(attempts)/\(maxAttempts)...")
            try await Task.sleep(nanoseconds: 5_000_000_000)

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

    func makeRequest(request: VideoGenerationRequest) async throws -> VideoGenerationResponse {
        guard let url = URL(string: model.modelGenerateBaseURL) else {
            return VideoGenerationResponse(
                status: .FAILED,
                errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Invalid URL"
            )
        }

        let aspectRatio = mapToSeedanceAspectRatio(dimension: request.artDimensions)
        let resolution = mapToResolution(request.artDimensions)
        let duration = request.durationSeconds ?? 5

        do {
            let headers: [String: String] = [
                "Authorization": "Bearer \(request.connectionSecret)",
                "Content-Type": "application/json",
            ]
            
            var imageUrl: String? = nil
            var lastFrameUrl: String? = nil
            
            if let clientImage = request.clientImage {
                imageUrl = try await ReplicateFileUploader.uploadImage(base64Image: clientImage, apiToken: request.connectionSecret)
            }
            
            if let clientLastFrame = request.clientLastFrame, imageUrl != nil {
                lastFrameUrl = try await ReplicateFileUploader.uploadImage(base64Image: clientLastFrame, apiToken: request.connectionSecret)
            }

            let serviceRequest = ServiceRequest(
                prompt: request.prompt ?? "",
                duration: duration,
                resolution: resolution,
                aspectRatio: aspectRatio,
                image: imageUrl,
                lastFrameImage: lastFrameUrl
            )

            let initialResponse = try await NetworkAdapter.shared.performRequest(
                url: url,
                method: "POST",
                body: [
                    "input": serviceRequest,
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
                    if let error = data["error"] as? String {
                        return VideoGenerationResponse(
                            status: .FAILED,
                            errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                            errorMessage: error
                        )
                    }
                default:
                    return VideoGenerationResponse(
                        status: .FAILED,
                        errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                        errorMessage: "Unexpected response"
                    )
                }

                guard let requestId = requestId else {
                    return VideoGenerationResponse(
                        status: .FAILED,
                        errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                        errorMessage: "Failed to initiate request"
                    )
                }

                guard let statusUrl = URL(string: model.modelStatusBaseURL!) else {
                    return VideoGenerationResponse(
                        status: .FAILED,
                        errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                        errorMessage: "Invalid URL for status check"
                    )
                }

                let finalResponse = try await pollForResult(requestId: requestId, url: statusUrl, headers: headers)

                return try transformResponse(request: request, response: finalResponse)
            } catch {
                return VideoGenerationResponse(
                    status: EnumGenerationStatus.FAILED,
                    errorCode: EnumGenerateVideoAdapterErrorCode.TRANSFORM_RESPONSE_ERROR,
                    errorMessage: "Failed with error: \(error)"
                )
            }
        } catch {
            return VideoGenerationResponse(
                status: EnumGenerationStatus.FAILED,
                errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Failed with error: \(error)"
            )
        }
    }
}

