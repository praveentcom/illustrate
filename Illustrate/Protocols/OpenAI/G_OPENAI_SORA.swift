import Foundation

class G_OPENAI_SORA_BASE: VideoGenerationProtocol {
    let modelCode: EnumProviderModelCode
    let modelName: String
    
    var model: ProviderModel {
        ProviderService.shared.model(by: modelCode.modelId.uuidString)!
    }
    
    var defaultDuration: Int {
        model.modelSupportedParams.supportedDurations.first ?? 4
    }
    
    init(modelCode: EnumProviderModelCode, modelName: String) {
        self.modelCode = modelCode
        self.modelName = modelName
    }
    
    func getCreditsUsed(request: VideoGenerationRequest) -> Double {
        return CostEstimator.getCreditsUsed(request: request)
    }

    struct ServiceRequest: Codable {
        let model: String
        let prompt: String
        let seconds: Int
        let size: String

        init(model: String, prompt: String, seconds: Int, size: String) {
            self.model = model
            self.prompt = prompt
            self.seconds = seconds
            self.size = size
        }
    }

    func transformRequest(request: VideoGenerationRequest) -> ServiceRequest {
        let duration = request.durationSeconds ?? defaultDuration
        let size = request.artDimensions
        
        return ServiceRequest(
            model: modelName,
            prompt: request.prompt ?? "",
            seconds: duration,
            size: size
        )
    }

    func transformResponse(request: VideoGenerationRequest, response: NetworkResponseData) throws -> VideoGenerationResponse {
        return VideoGenerationResponse(
            status: .FAILED,
            errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
            errorMessage: "Use makeRequest directly for Sora models"
        )
    }
    
    func pollForResult(videoId: String, apiKey: String, maxAttempts: Int = 120) async throws -> [String: Any] {
        var attempts = 0
        
        while attempts < maxAttempts {
            print("Polling for Sora video result - attempt \(attempts + 1)/\(maxAttempts)...")
            try await Task.sleep(nanoseconds: 5_000_000_000)
            
            guard let statusURL = URL(string: "https://api.openai.com/v1/videos/\(videoId)") else {
                throw NSError(domain: "Invalid status URL", code: -1, userInfo: nil)
            }
            
            let response = try await NetworkAdapter.shared.performRequest(
                url: statusURL,
                method: "GET",
                body: nil as String?,
                headers: [
                    "Authorization": "Bearer \(apiKey)",
                    "Content-Type": "application/json"
                ]
            )
            
            switch response {
            case let .dictionary(_, data):
                if let status = data["status"] as? String {
                    if status == "completed" {
                        return data
                    } else if status == "failed" {
                        let errorMessage = (data["error"] as? [String: Any])?["message"] as? String ?? "Video generation failed"
                        throw NSError(domain: errorMessage, code: -1, userInfo: nil)
                    }
                }
                
                if let error = data["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw NSError(domain: message, code: -1, userInfo: nil)
                }
            default:
                break
            }
            
            attempts += 1
        }
        
        throw NSError(domain: "Polling exceeded max attempts (10 minutes)", code: -1, userInfo: nil)
    }
    
    func downloadVideo(url: String, apiKey: String) async throws -> Data {
        guard let downloadURL = URL(string: url) else {
            throw NSError(domain: "Invalid download URL", code: -1, userInfo: nil)
        }
        
        var request = URLRequest(url: downloadURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "Failed to download video", code: -1, userInfo: nil)
        }
        
        return data
    }

    func makeRequest(request: VideoGenerationRequest) async throws -> VideoGenerationResponse {
        guard let url = URL(string: model.modelGenerateBaseURL) else {
            return VideoGenerationResponse(
                status: .FAILED,
                errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Invalid URL"
            )
        }

        let transformedRequest = transformRequest(request: request)
        
        do {
            let headers: [String: String] = [
                "Authorization": "Bearer \(request.providerSecret)",
                "Content-Type": "multipart/form-data",
                "Accept": "application/json",
            ]
            
            let initialResponse = try await NetworkAdapter.shared.performRequest(
                url: url,
                method: "POST",
                body: transformedRequest,
                headers: headers
            )
            
            var videoId: String? = nil
            var videoURL: String? = nil
            var status: String? = nil
            
            switch initialResponse {
            case let .dictionary(_, data):
                if let error = data["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    return VideoGenerationResponse(
                        status: .FAILED,
                        errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                        errorMessage: message
                    )
                }
                
                videoId = data["id"] as? String
                status = data["status"] as? String
                
                if status == "completed",
                   let outputVideo = data["output_video"] as? String {
                    videoURL = outputVideo
                }
            default:
                return VideoGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                    errorMessage: "Unexpected response format"
                )
            }
            
            if let url = videoURL {
                let videoData = try await downloadVideo(url: url, apiKey: request.providerSecret)
                let base64Video = videoData.base64EncodedString()
                
                return VideoGenerationResponse(
                    status: .GENERATED,
                    base64: base64Video,
                    cost: getCreditsUsed(request: request),
                    modelPrompt: request.prompt
                )
            }
            
            guard let id = videoId else {
                return VideoGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                    errorMessage: "No video ID in response"
                )
            }
            
            let finalResult = try await pollForResult(
                videoId: id,
                apiKey: request.providerSecret
            )
            
            if let outputVideo = finalResult["output_video"] as? String {
                let videoData = try await downloadVideo(url: outputVideo, apiKey: request.providerSecret)
                let base64Video = videoData.base64EncodedString()
                
                return VideoGenerationResponse(
                    status: .GENERATED,
                    base64: base64Video,
                    cost: getCreditsUsed(request: request),
                    modelPrompt: request.prompt
                )
            }
            
            if let error = finalResult["error"] as? [String: Any],
               let message = error["message"] as? String {
                return VideoGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                    errorMessage: message
                )
            }
            
            return VideoGenerationResponse(
                status: .FAILED,
                errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Failed to extract video from response"
            )

        } catch {
            return VideoGenerationResponse(
                status: EnumGenerationStatus.FAILED,
                errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Failed with error: \(error.localizedDescription)"
            )
        }
    }
}


class G_OPENAI_SORA_2: G_OPENAI_SORA_BASE {
    init() {
        super.init(modelCode: .OPENAI_SORA_2, modelName: "sora-2")
    }
}

class G_OPENAI_SORA_2_PRO: G_OPENAI_SORA_BASE {
    init() {
        super.init(modelCode: .OPENAI_SORA_2_PRO, modelName: "sora-2-pro")
    }
}

