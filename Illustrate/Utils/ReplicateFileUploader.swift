import Foundation

struct ReplicateFileUploader {
    
    static func uploadImage(base64Image: String, apiToken: String) async throws -> String {
        guard let uploadUrl = URL(string: "https://api.replicate.com/v1/files") else {
            throw NSError(domain: "Invalid upload URL", code: -1, userInfo: nil)
        }
        
        let cleanBase64 = base64Image.replacingOccurrences(
            of: "^data:.*;base64,",
            with: "",
            options: .regularExpression
        )
        
        guard let imageData = Data(base64Encoded: cleanBase64) else {
            throw NSError(domain: "Invalid base64 image data", code: -1, userInfo: nil)
        }
        
        let boundary = UUID().uuidString
        var bodyData = Data()
        
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"content\"; filename=\"image.png\"\r\n".data(using: .utf8)!)
        bodyData.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        bodyData.append(imageData)
        bodyData.append("\r\n".data(using: .utf8)!)
        
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"metadata\"\r\n".data(using: .utf8)!)
        bodyData.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
        bodyData.append("{\"agent\":\"illustrate\"}".data(using: .utf8)!)
        bodyData.append("\r\n".data(using: .utf8)!)
        
        bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        var request = URLRequest(url: uploadUrl)
        request.httpMethod = "POST"
        request.setValue("Token \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Invalid response", code: -1, userInfo: nil)
        }
        
        if httpResponse.statusCode >= 400 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "Upload failed: \(errorMessage)", code: httpResponse.statusCode, userInfo: nil)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let urls = json["urls"] as? [String: Any],
              let getUrl = urls["get"] as? String else {
            throw NSError(domain: "Failed to parse upload response", code: -1, userInfo: nil)
        }
        
        return getUrl
    }
}

