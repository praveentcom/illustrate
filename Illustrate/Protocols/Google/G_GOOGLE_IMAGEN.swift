import Foundation

class G_GOOGLE_IMAGEN_BASE: ImageGenerationProtocol {
    let modelCode: EnumProviderModelCode
    let costPerImage: Double
    let supportsImageSize: Bool
    
    var model: ProviderModel {
        ProviderService.shared.model(by: modelCode.modelId.uuidString)!
    }
    
    init(modelCode: EnumProviderModelCode, costPerImage: Double, supportsImageSize: Bool) {
        self.modelCode = modelCode
        self.costPerImage = costPerImage
        self.supportsImageSize = supportsImageSize
    }
    
    func getCreditsUsed(request: ImageGenerationRequest) -> Double {
        return CostEstimator.getCreditsUsed(request: request)
    }

    struct Instance: Codable {
        var prompt: String
    }

    struct Parameters: Codable {
        var aspectRatio: String?
        var sampleCount: Int?
        var imageSize: String?
        
        init(aspectRatio: String?, sampleCount: Int? = 1, imageSize: String? = nil) {
            self.aspectRatio = aspectRatio
            self.sampleCount = sampleCount
            self.imageSize = imageSize
        }
    }

    struct ServiceRequest: Codable {
        var instances: [Instance]
        var parameters: Parameters?

        init(prompt: String, aspectRatio: String?, imageSize: String?) {
            self.instances = [Instance(prompt: prompt)]
            self.parameters = Parameters(aspectRatio: aspectRatio, sampleCount: 1, imageSize: imageSize)
        }
    }

    func transformRequest(request: ImageGenerationRequest) -> ServiceRequest {
        let aspectRatio = convertToAspectRatio(request.artDimensions)
        var imageSize: String? = nil
        
        if supportsImageSize {
            imageSize = request.artQuality == .HD ? "2048" : "1024"
        }
        
        return ServiceRequest(prompt: request.prompt, aspectRatio: aspectRatio, imageSize: imageSize)
    }

    private func convertToAspectRatio(_ dimensions: String) -> String? {
        let parts = dimensions.lowercased().split(separator: "x")
        guard parts.count == 2,
              let width = Int(parts[0]),
              let height = Int(parts[1]) else {
            return "1:1"
        }
        
        let ratio = Double(width) / Double(height)
        
        if abs(ratio - 1.0) < 0.1 {
            return "1:1"
        } else if abs(ratio - 0.75) < 0.1 {
            return "3:4"
        } else if abs(ratio - 1.333) < 0.1 {
            return "4:3"
        } else if abs(ratio - 0.5625) < 0.1 {
            return "9:16"
        } else if abs(ratio - 1.777) < 0.1 {
            return "16:9"
        }
        
        return "1:1"
    }

    func transformResponse(request: ImageGenerationRequest, response: NetworkResponseData) throws -> ImageGenerationResponse {
        switch response {
        case let .dictionary(_, data):
            if let predictions = data["predictions"] as? [[String: Any]],
               let firstPrediction = predictions.first,
               let base64Data = firstPrediction["bytesBase64Encoded"] as? String {
                return ImageGenerationResponse(
                    status: .GENERATED,
                    base64: base64Data,
                    cost: getCreditsUsed(request: request),
                    modelPrompt: request.prompt
                )
            }
            
            if let error = data["error"] as? [String: Any],
               let message = error["message"] as? String {
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
                errorMessage: "Unexpected response format"
            )
        }

        return ImageGenerationResponse(
            status: .FAILED,
            errorCode: EnumGenerateImageAdapterErrorCode.MODEL_ERROR,
            errorMessage: "Invalid response - no image data found"
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

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "key", value: request.providerSecret)]

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

class G_GOOGLE_IMAGEN_3: G_GOOGLE_IMAGEN_BASE {
    init() {
        super.init(
            modelCode: .GOOGLE_IMAGEN_3,
            costPerImage: 0.03,
            supportsImageSize: false
        )
    }
}

class G_GOOGLE_IMAGEN_4_FAST: G_GOOGLE_IMAGEN_BASE {
    init() {
        super.init(
            modelCode: .GOOGLE_IMAGEN_4_FAST,
            costPerImage: 0.02,
            supportsImageSize: false
        )
    }
}

class G_GOOGLE_IMAGEN_4_STANDARD: G_GOOGLE_IMAGEN_BASE {
    init() {
        super.init(
            modelCode: .GOOGLE_IMAGEN_4_STANDARD,
            costPerImage: 0.04,
            supportsImageSize: true
        )
    }
}

class G_GOOGLE_IMAGEN_4_ULTRA: G_GOOGLE_IMAGEN_BASE {
    init() {
        super.init(
            modelCode: .GOOGLE_IMAGEN_4_ULTRA,
            costPerImage: 0.06,
            supportsImageSize: true
        )
    }
}

