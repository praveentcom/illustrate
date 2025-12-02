import Foundation
import SwiftUI
import SwiftData
import KeychainSwift
import Combine

enum QueueItemStatus: String, Codable {
    case inProgress = "in_progress"
    case successful = "successful"
    case failed = "failed"
}

class QueueItem: Identifiable, ObservableObject {
    let id: UUID
    let prompt: String
    let createdAt: Date
    
    @Published var status: QueueItemStatus
    @Published var resultSetId: UUID?
    @Published var errorMessage: String?
    
    @Published var resultVideoSetId: UUID?
    @Published var isVideoGeneration: Bool
    
    var task: Task<Void, Never>?
    
    init(
        id: UUID = UUID(),
        prompt: String,
        status: QueueItemStatus = .inProgress,
        resultSetId: UUID? = nil,
        errorMessage: String? = nil,
        isVideoGeneration: Bool = false
    ) {
        self.id = id
        self.prompt = prompt
        self.createdAt = Date()
        self.status = status
        self.resultSetId = resultSetId
        self.errorMessage = errorMessage
        self.isVideoGeneration = isVideoGeneration
    }
    
    func cancel() {
        task?.cancel()
        task = nil
    }
}

@MainActor
class QueueManager: ObservableObject {
    static let shared = QueueManager()
    
    @Published var items: [QueueItem] = []
        
    func addItem(_ item: QueueItem) {
        items.insert(item, at: 0)
    }
    
    func removeItem(_ item: QueueItem) {
        items.removeAll { $0.id == item.id }
    }
    
    func removeItem(by id: UUID) {
        items.removeAll { $0.id == id }
    }
    
    func cancelItem(_ item: QueueItem) {
        item.cancel()
        item.status = .failed
        item.errorMessage = "Cancelled by user"
        objectWillChange.send()
    }
    
    func cancelItem(by id: UUID) {
        if let item = items.first(where: { $0.id == id }) {
            cancelItem(item)
        }
    }
    
    func updateItemStatus(_ id: UUID, status: QueueItemStatus, resultSetId: UUID? = nil, errorMessage: String? = nil) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].status = status
            items[index].resultSetId = resultSetId
            items[index].errorMessage = errorMessage
            objectWillChange.send()
        }
    }
    
    func updateVideoItemStatus(_ id: UUID, status: QueueItemStatus, resultVideoSetId: UUID? = nil, errorMessage: String? = nil) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].status = status
            items[index].resultVideoSetId = resultVideoSetId
            items[index].errorMessage = errorMessage
            objectWillChange.send()
        }
    }
    
    func clearAllFailed() {
        items.removeAll { $0.status == .failed }
    }
    
    func clearAllCompleted() {
        items.removeAll { $0.status == .successful }
    }
        
    var inProgressItems: [QueueItem] {
        items.filter { $0.status == .inProgress }
    }
    
    var successfulItems: [QueueItem] {
        items.filter { $0.status == .successful }
    }
    
    var failedItems: [QueueItem] {
        items.filter { $0.status == .failed }
    }
    
    var hasActiveItems: Bool {
        !inProgressItems.isEmpty
    }
    
    var totalCount: Int {
        items.count
    }
    
    func submitImageGeneration(
        request: ImageGenerationRequest,
        modelContext: ModelContext
    ) -> QueueItem {
        let item = QueueItem(
            prompt: request.prompt,
            isVideoGeneration: false
        )
        
        addItem(item)
        
        item.task = Task {
            await performImageGeneration(
                queueItemId: item.id,
                request: request,
                modelContext: modelContext
            )
        }
        
        return item
    }
    
    private func performImageGeneration(
        queueItemId: UUID,
        request: ImageGenerationRequest,
        modelContext: ModelContext
    ) async {
        let adapter = GenerateImageAdapter(
            imageGenerationRequest: request,
            modelContext: modelContext
        )
        
        let response = await adapter.makeRequest()
        
        await MainActor.run {
            if response.status == .GENERATED, let setId = response.set?.id {
                updateItemStatus(queueItemId, status: .successful, resultSetId: setId)
            } else {
                updateItemStatus(
                    queueItemId,
                    status: .failed,
                    errorMessage: response.errorMessage ?? "Generation failed"
                )
            }
        }
    }
    
    func submitVideoGeneration(
        request: VideoGenerationRequest,
        modelContext: ModelContext
    ) -> QueueItem {
        let item = QueueItem(
            prompt: request.prompt!,
            isVideoGeneration: true
        )
        
        addItem(item)
        
        item.task = Task {
            await performVideoGeneration(
                queueItemId: item.id,
                request: request,
                modelContext: modelContext
            )
        }
        
        return item
    }
    
    private func performVideoGeneration(
        queueItemId: UUID,
        request: VideoGenerationRequest,
        modelContext: ModelContext
    ) async {
        let adapter = GenerateVideoAdapter(
            videoGenerationRequest: request,
            modelContext: modelContext
        )
        
        let response = await adapter.makeRequest()
        
        await MainActor.run {
            if response.status == .GENERATED, let setId = response.set?.id {
                updateVideoItemStatus(queueItemId, status: .successful, resultVideoSetId: setId)
            } else {
                updateVideoItemStatus(
                    queueItemId,
                    status: .failed,
                    errorMessage: response.errorMessage ?? "Video generation failed"
                )
            }
        }
    }
}

