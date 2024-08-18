import Foundation

enum NetworkResponseData {
    case dictionary(statusCode: Int, data: [String: Any])
    case array(statusCode: Int, data: [[String: Any]])
}

struct NetworkRequestAttachment {
    var name: String
    var mimeType: String
    var data: Data
}

class NetworkAdapter {
    static let shared = NetworkAdapter()

    private init() {}

    func performRequest<T: Codable>(
        url: URL,
        method: String,
        body: T?,
        headers: [String: String]? = nil,
        attachments: [NetworkRequestAttachment]? = nil
    ) async throws -> NetworkResponseData {
        var request = URLRequest(url: url)
        request.httpMethod = method
                
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        if (request.httpMethod != "GET") {
            if let body = body {
                if request.value(forHTTPHeaderField: "Content-Type") == "multipart/form-data" {
                    let boundary = UUID().uuidString
                    let contentType = "multipart/form-data; boundary=\(boundary)"
                    request.setValue(contentType, forHTTPHeaderField: "Content-Type")
                    
                    let multipartBody = try createMultipartBody(from: body, boundary: boundary, attachments: attachments)
                    request.httpBody = multipartBody
                } else {
                    do {
                        request.httpBody = try JSONEncoder().encode(body)
                    } catch {
                        throw error
                    }
                }
            }
        }
        
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Invalid Response", code: -1, userInfo: nil)
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            
            if let dict = json as? [String: Any] {
                return .dictionary(
                    statusCode: httpResponse.statusCode,
                    data: dict
                )
            } else if let array = json as? [[String: Any]] {
                return .array(
                    statusCode: httpResponse.statusCode,
                    data: array
                )
            } else {
                throw NSError(domain: "Invalid JSON", code: -1, userInfo: nil)
            }
        } catch {
            throw error
        }
    }

    private func createMultipartBody<T: Codable>(
        from body: T,
        boundary: String,
        attachments: [NetworkRequestAttachment]?
    ) throws -> Data {
        var bodyData = Data()
        let mirror = Mirror(reflecting: body)

        for child in mirror.children {
            guard let key = child.label else { continue }
            
            // Handle different types by converting them to String
            if let value = child.value as? String {
                bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
                bodyData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                bodyData.append("\(value)\r\n".data(using: .utf8)!)
            } else if let value = child.value as? Int {
                bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
                bodyData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                bodyData.append("\(String(value))\r\n".data(using: .utf8)!)
            } else if let value = child.value as? Double {
                bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
                bodyData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                bodyData.append("\(String(value))\r\n".data(using: .utf8)!)
            } else if let value = child.value as? Bool {
                bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
                bodyData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                bodyData.append("\(String(value))\r\n".data(using: .utf8)!)
            }
        }
        
        if let attachments = attachments {
            for attachment in attachments {
                bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
                bodyData.append("Content-Disposition: form-data; name=\"\(attachment.name)\"; filename=\"\(attachment.name)\"\r\n".data(using: .utf8)!)
                bodyData.append("Content-Type: \(attachment.mimeType)\r\n\r\n".data(using: .utf8)!)
                bodyData.append(attachment.data)
                bodyData.append("\r\n".data(using: .utf8)!)
            }
        }

        bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return bodyData
    }
}
