import Foundation

class G_HUGGING_FACE_FLUX_DEV: ImageGenerationProtocol {
    func getCreditsUsed(request: ImageGenerationRequest) -> Double {
        return 0.00;
    }

    let model: ConnectionModel = connectionModels.first(where: { $0.modelCode == EnumConnectionModelCode.HUGGING_FACE_FLUX_DEV })!

    struct ServiceRequest: Codable {
        let inputs: String
        
        init(inputs: String) {
            self.inputs = inputs
        }
    }

    func transformRequest(request: ImageGenerationRequest) -> ServiceRequest {

        return ServiceRequest(
            inputs: request.artVariant != EnumArtVariant.NORMAL ? "\(request.artVariant.rawValue) - \(request.prompt)" : request.prompt
        )
    }

    func transformResponse(request: ImageGenerationRequest, response: NetworkResponseData) throws -> ImageGenerationResponse {
        print(response)
        
        switch response {
        case .image(_, let base64, _):
            return ImageGenerationResponse(
                status: .GENERATED,
                base64: base64.replacingOccurrences(
                    of: "^data:.*;base64,",
                    with: "",
                    options: .regularExpression
                ),
                cost: getCreditsUsed(request: request)
            )
        case .dictionary(_, let data):
            if let message = data["error"] as? String {
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
                "Authorization": "Bearer \(request.connectionSecret)",
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
