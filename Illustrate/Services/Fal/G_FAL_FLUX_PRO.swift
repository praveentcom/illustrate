import Foundation

class G_FAL_FLUX_PRO: ImageGenerationProtocol {
    func getCreditsUsed(request: ImageGenerationRequest) -> Double {
        return 0.05;
    }

    let model: ConnectionModel = connectionModels.first(where: { $0.modelCode == EnumConnectionModelCode.FAL_FLUX_PRO })!

    struct ServiceRequest: Codable {
        let prompt: String
        let num_images: Int
        let image_size: String
        let sync_mode: Bool
        let enable_safety_checker: Bool
        let safety_tolerance: String
        
        init(prompt: String, aspectRatio: String) {
            self.prompt = prompt
            self.num_images = 1
            self.image_size = aspectRatio
            self.sync_mode = true
            self.enable_safety_checker = false
            self.safety_tolerance = "5"
        }
    }
    
    func getImageDimensions(_ artDimensions: String) -> String {
        switch artDimensions {
        case "1024x1024":
            return "square_hd"
        case "1920x1080":
            return "landscape_16_9"
        case "1440x1080":
            return "landscape_4_3"
        case "1080x1920":
            return "portrait_16_9"
        case "1080x1440":
            return "portrait_4_3"
        default:
            return "square_hd"
        }
    }

    func transformRequest(request: ImageGenerationRequest) -> ServiceRequest {
        let aspectRatio = getImageDimensions(request.artDimensions)

        return ServiceRequest(
            prompt: request.artVariant != EnumArtVariant.NORMAL ? "\(request.artVariant.rawValue) - \(request.prompt)" : request.prompt,
            aspectRatio: aspectRatio
        )
    }

    func transformResponse(request: ImageGenerationRequest, response: NetworkResponseData) throws -> ImageGenerationResponse {
        switch response {
        case .dictionary(_, let data):
            if let output = data["images"] as? [[String: Any]],
               let base64OrUrl = output.first?["url"] as? String {
                    var base64: String {
                        if (base64OrUrl.contains("base64")) {
                            return base64OrUrl.replacingOccurrences(
                                of: "^data:.*;base64,",
                                with: "",
                                options: .regularExpression
                            )
                        } else {
                            let url = URL(string: base64OrUrl)!
                            let jpegData = try? Data(contentsOf: url)
                            let base64 = jpegData?.base64EncodedString() ?? ""
                            
                            return base64
                        }
                    }
                    return ImageGenerationResponse(
                        status: .GENERATED,
                        base64: base64,
                        cost: getCreditsUsed(request: request)
                    )
                }
            if let error = data["detail"] as? String {
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

    func makeRequest(request: ImageGenerationRequest) async throws -> ImageGenerationResponse {
        guard let url = URL(string: model.modelGenerateBaseURL) else {
            throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
        }

        let transformedRequest = transformRequest(request: request)

        do {
            let headers: [String: String] = [
                "Authorization": "Key \(request.connectionSecret)",
                "Content-Type": "application/json"
            ]
                                    
            let response = try await NetworkAdapter.shared.performRequest(
                url: url,
                method: "POST",
                body: transformedRequest,
                headers: headers
            )
            
            do {
                return try transformResponse(request: request, response: response)
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
