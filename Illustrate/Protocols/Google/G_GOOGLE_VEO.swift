import Foundation

class G_GOOGLE_VEO_BASE: VideoGenerationProtocol {
    let modelCode: EnumConnectionModelCode
    let costPerSecond: Double
    
    var model: ConnectionModel {
        ConnectionService.shared.model(by: modelCode.modelId.uuidString)!
    }
    
    var supportsVideoInput: Bool {
        model.modelSupportedParams.supportsVideoInput
    }
    
    var supportsAudio: Bool {
        model.modelSupportedParams.supportsAudio
    }
    
    var defaultDuration: Int {
        model.modelSupportedParams.supportedDurations.last ?? 8
    }
    
    init(modelCode: EnumConnectionModelCode, costPerSecond: Double) {
        self.modelCode = modelCode
        self.costPerSecond = costPerSecond
    }
    
    func getCreditsUsed(request: VideoGenerationRequest) -> Double {
        return CostEstimator.getCreditsUsed(request: request)
    }

    struct ImageObject: Codable {
        var bytesBase64Encoded: String
        var mimeType: String
        
        init(base64: String) {
            self.bytesBase64Encoded = base64
            self.mimeType = "image/png"
        }
    }
    
    struct VideoObject: Codable {
        var bytesBase64Encoded: String
        var mimeType: String
        
        init(base64: String) {
            self.bytesBase64Encoded = base64
            self.mimeType = "video/mp4"
        }
    }

    struct Instance: Codable {
        var prompt: String
        var image: ImageObject?
        var lastFrame: ImageObject?
        var video: VideoObject?
        
        init(
            prompt: String,
            image: ImageObject? = nil,
            lastFrame: ImageObject? = nil,
            video: VideoObject? = nil
        ) {
            self.prompt = prompt
            self.image = image
            self.lastFrame = lastFrame
            self.video = video
        }
    }
    
    struct Parameters: Codable {
        var aspectRatio: String?
        var durationSeconds: Int?
        var negativePrompt: String?
        var generateAudio: Bool?
        var resolution: String?
        
        init(
            aspectRatio: String? = nil,
            durationSeconds: Int? = nil,
            negativePrompt: String? = nil,
            generateAudio: Bool? = nil,
            resolution: String? = nil
        ) {
            self.aspectRatio = aspectRatio
            self.durationSeconds = durationSeconds
            self.negativePrompt = negativePrompt
            self.generateAudio = generateAudio
            self.resolution = resolution
        }
    }

    struct ServiceRequest: Codable {
        var instances: [Instance]
        var parameters: Parameters?

        init(instance: Instance, parameters: Parameters? = nil) {
            self.instances = [instance]
            self.parameters = parameters
        }
    }

    func transformRequest(request: VideoGenerationRequest) -> ServiceRequest {
        let aspectRatio = convertToAspectRatio(request.artDimensions)
        let resolution = convertToResolution(request.artDimensions)
        let duration = request.durationSeconds ?? defaultDuration
        
        var imageObj: ImageObject? = nil
        if let clientImage = request.clientImage {
            let cleanBase64 = clientImage.replacingOccurrences(
                of: "^data:.*;base64,",
                with: "",
                options: .regularExpression
            )
            imageObj = ImageObject(base64: cleanBase64)
        }
        
        var lastFrameObj: ImageObject? = nil
        if let lastFrame = request.clientLastFrame {
            let cleanBase64 = lastFrame.replacingOccurrences(
                of: "^data:.*;base64,",
                with: "",
                options: .regularExpression
            )
            lastFrameObj = ImageObject(base64: cleanBase64)
        }
        
        var videoObj: VideoObject? = nil
        if supportsVideoInput, let clientVideo = request.clientVideo {
            let cleanBase64 = clientVideo.replacingOccurrences(
                of: "^data:.*;base64,",
                with: "",
                options: .regularExpression
            )
            videoObj = VideoObject(base64: cleanBase64)
        }
        
        let instance = Instance(
            prompt: request.prompt ?? "",
            image: imageObj,
            lastFrame: lastFrameObj,
            video: videoObj
        )
        
        let parameters = Parameters(
            aspectRatio: aspectRatio,
            durationSeconds: duration,
            negativePrompt: request.negativePrompt,
            resolution: resolution
        )
        
        return ServiceRequest(instance: instance, parameters: parameters)
    }

    private func convertToAspectRatio(_ dimensions: String) -> String {
        let parts = dimensions.lowercased().split(separator: "x")
        guard parts.count == 2,
              let width = Int(parts[0]),
              let height = Int(parts[1]) else {
            return "16:9"
        }
        
        let ratio = Double(width) / Double(height)
        
        if ratio > 1.0 {
            return "16:9"
        } else {
            return "9:16"
        }
    }
    
    private func convertToResolution(_ dimensions: String) -> String? {
        let parts = dimensions.lowercased().split(separator: "x")
        guard parts.count == 2,
              let width = Int(parts[0]),
              let height = Int(parts[1]) else {
            return "720p"
        }
        
        let maxDim = max(width, height)
        if maxDim >= 1080 {
            return "1080p"
        }
        return "720p"
    }

    func pollForResult(operationName: String, baseURL: String, apiKey: String, maxAttempts: Int = 60) async throws -> [String: Any] {
        var attempts = 0
        
        while attempts < maxAttempts {
            print("Polling for video result - attempt \(attempts + 1)/\(maxAttempts)...")
            try await Task.sleep(nanoseconds: 10_000_000_000)
            
            guard let statusURL = URL(string: "\(baseURL)/\(operationName)?key=\(apiKey)") else {
                throw NSError(domain: "Invalid status URL", code: -1, userInfo: nil)
            }
            
            let response = try await NetworkAdapter.shared.performRequest(
                url: statusURL,
                method: "GET",
                body: nil as String?,
                headers: ["Content-Type": "application/json"]
            )
            
            switch response {
            case let .dictionary(_, data):
                if let done = data["done"] as? Bool, done {
                    return data
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
    
    func downloadVideo(uri: String, apiKey: String) async throws -> Data {
        let separator = uri.contains("?") ? "&" : "?"
        guard let downloadURL = URL(string: "\(uri)\(separator)key=\(apiKey)") else {
            throw NSError(domain: "Invalid download URL", code: -1, userInfo: nil)
        }
        
        var request = URLRequest(url: downloadURL)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "Failed to download video", code: -1, userInfo: nil)
        }
        
        return data
    }

    func transformResponse(request: VideoGenerationRequest, response: NetworkResponseData) throws -> VideoGenerationResponse {
        return VideoGenerationResponse(
            status: .FAILED,
            errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
            errorMessage: "Use makeRequest directly for Veo models"
        )
    }

    func makeRequest(request: VideoGenerationRequest) async throws -> VideoGenerationResponse {
        guard let url = URL(string: model.modelGenerateBaseURL) else {
            return VideoGenerationResponse(
                status: .FAILED,
                errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Invalid URL"
            )
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "key", value: request.connectionSecret)]

        guard let finalURL = components.url else {
            return VideoGenerationResponse(
                status: .FAILED,
                errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                errorMessage: "Failed to construct URL with API key"
            )
        }

        let transformedRequest = transformRequest(request: request)
        
        do {
            let initialResponse = try await NetworkAdapter.shared.performRequest(
                url: finalURL,
                method: "POST",
                body: transformedRequest,
                headers: ["Content-Type": "application/json"]
            )
            
            var operationName: String? = nil
            
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
                
                operationName = data["name"] as? String
            default:
                return VideoGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                    errorMessage: "Unexpected response format"
                )
            }
            
            guard let opName = operationName else {
                return VideoGenerationResponse(
                    status: .FAILED,
                    errorCode: EnumGenerateVideoAdapterErrorCode.MODEL_ERROR,
                    errorMessage: "No operation name in response"
                )
            }
            
            let statusBaseURL = model.modelStatusBaseURL ?? "https://generativelanguage.googleapis.com/v1beta"
            let finalResult = try await pollForResult(
                operationName: opName,
                baseURL: statusBaseURL,
                apiKey: request.connectionSecret
            )
            
            if let response = finalResult["response"] as? [String: Any],
               let generateVideoResponse = response["generateVideoResponse"] as? [String: Any],
               let generatedSamples = generateVideoResponse["generatedSamples"] as? [[String: Any]],
               let firstSample = generatedSamples.first,
               let video = firstSample["video"] as? [String: Any],
               let videoURI = video["uri"] as? String {
                
                let videoData = try await downloadVideo(uri: videoURI, apiKey: request.connectionSecret)
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


class G_GOOGLE_VEO_31: G_GOOGLE_VEO_BASE {
    init() {
        super.init(modelCode: .GOOGLE_VEO_31, costPerSecond: 0.40)
    }
}

class G_GOOGLE_VEO_31_FAST: G_GOOGLE_VEO_BASE {
    init() {
        super.init(modelCode: .GOOGLE_VEO_31_FAST, costPerSecond: 0.15)
    }
}

class G_GOOGLE_VEO_3: G_GOOGLE_VEO_BASE {
    init() {
        super.init(modelCode: .GOOGLE_VEO_3, costPerSecond: 0.40)
    }
}

class G_GOOGLE_VEO_3_FAST: G_GOOGLE_VEO_BASE {
    init() {
        super.init(modelCode: .GOOGLE_VEO_3_FAST, costPerSecond: 0.15)
    }
}

class G_GOOGLE_VEO_2: G_GOOGLE_VEO_BASE {
    init() {
        super.init(modelCode: .GOOGLE_VEO_2, costPerSecond: 0.35)
    }
}

