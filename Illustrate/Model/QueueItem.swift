import Foundation
import CloudKit
import SwiftData
import SwiftUI

enum EnumQueueItemStatus: String, Codable, CaseIterable, Identifiable {
    var id: String { self.rawValue }
    
    case IN_PROGRESS = "In Progress"
    case SUCCESSFUL = "Successful"
    case FAILED = "Failed"
}

@Model
class QueueItem: Identifiable, Codable {
    enum CodingKeys: CodingKey {
        case id
        case createdAt
        case updatedAt
        case status
        case request
        case response
        case errorMessage
        case setId
        case setType
    }
    
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var status: EnumQueueItemStatus = .IN_PROGRESS
    var request: ImageGenerationRequest? = nil
    var response: ImageSetResponse? = nil
    var errorMessage: String? = nil
    var setId: UUID? = nil
    var setType: EnumSetType = .GENERATE
    
    init(
        request: ImageGenerationRequest,
        setType: EnumSetType = .GENERATE
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.status = .IN_PROGRESS
        self.request = request
        self.setType = setType
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        status = try container.decode(EnumQueueItemStatus.self, forKey: .status)
        request = try container.decodeIfPresent(ImageGenerationRequest.self, forKey: .request)
        response = try container.decodeIfPresent(ImageSetResponse.self, forKey: .response)
        errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        setId = try container.decodeIfPresent(UUID.self, forKey: .setId)
        setType = try container.decode(EnumSetType.self, forKey: .setType)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(request, forKey: .request)
        try container.encodeIfPresent(response, forKey: .response)
        try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
        try container.encodeIfPresent(setId, forKey: .setId)
        try container.encode(setType, forKey: .setType)
    }
}
