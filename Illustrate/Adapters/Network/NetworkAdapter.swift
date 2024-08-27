import Foundation

enum NetworkResponseData {
    case dictionary(statusCode: Int, data: [String: Any])
    case array(statusCode: Int, data: [[String: Any]])
    case image(statusCode: Int, base64: String, mimeType: String)
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

        if request.httpMethod != "GET" {
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

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 120

        let session = URLSession(configuration: configuration)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Invalid Response", code: -1, userInfo: nil)
        }

        if httpResponse.statusCode == 403 {
            throw NSError(domain: "Forbidden request", code: -1, userInfo: nil)
        } else if httpResponse.statusCode == 404 {
            throw NSError(domain: "Not found", code: -1, userInfo: nil)
        } else if httpResponse.statusCode == 500 {
            throw NSError(domain: "Internal server error", code: -1, userInfo: nil)
        } else if httpResponse.statusCode == 503 {
            throw NSError(domain: "Service unavailable", code: -1, userInfo: nil)
        } else if httpResponse.statusCode == 504 {
            throw NSError(domain: "Gateway timeout", code: -1, userInfo: nil)
        } else if httpResponse.statusCode == 429 {
            throw NSError(domain: "Too many requests", code: -1, userInfo: nil)
        }

        if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") {
            if contentType.contains("image/jpeg") || contentType.contains("image/png") {
                let base64String = data.base64EncodedString()
                return .image(statusCode: httpResponse.statusCode, base64: base64String, mimeType: contentType)
            }
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
