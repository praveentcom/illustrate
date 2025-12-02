import Foundation
import SwiftData
import SwiftUI
import Combine

/// Service class responsible for managing the generation queue
@MainActor
class GenerationQueueService: ObservableObject {
    static let shared = GenerationQueueService()
    
    @Published var queueItems: [QueueItem] = []
    private var modelContext: ModelContext?
    private var processingTask: Task<Void, Never>?
    private var cleanupTimer: Timer?
    
    // MARK: - Initialization
    
    private init() {
        startCleanupTimer()
    }
    
    // MARK: - Setup
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadQueueItems()
    }
    
    // MARK: - Queue Management
    
    func addToQueue(request: ImageGenerationRequest, setType: EnumSetType) -> QueueItem {
        guard let context = modelContext else {
            fatalError("ModelContext not set")
        }
        
        let queueItem = QueueItem(request: request, setType: setType)
        context.insert(queueItem)
        
        do {
            try context.save()
            queueItems.append(queueItem)
            
            // Start processing if not already running
            startProcessing()
            
            return queueItem
        } catch {
            print("Failed to save queue item: \(error)")
            return queueItem
        }
    }
    
    func removeFromQueue(_ item: QueueItem) {
        guard let context = modelContext else { return }
        
        context.delete(item)
        
        do {
            try context.save()
            queueItems.removeAll { $0.id == item.id }
        } catch {
            print("Failed to remove queue item: \(error)")
        }
    }
    
    func clearSuccessfulItems() {
        let successfulItems = queueItems.filter { $0.status == .SUCCESSFUL }
        successfulItems.forEach { removeFromQueue($0) }
    }
    
    func clearFailedItems() {
        let failedItems = queueItems.filter { $0.status == .FAILED }
        failedItems.forEach { removeFromQueue($0) }
    }
    
    // MARK: - Queue Processing
    
    private func startProcessing() {
        // Cancel existing task if any
        processingTask?.cancel()
        
        processingTask = Task {
            await processQueue()
        }
    }
    
    private func processQueue() async {
        guard let context = modelContext else { return }
        
        // Find next item to process
        guard let nextItem = queueItems.first(where: { $0.status == .IN_PROGRESS }) else {
            return
        }
        
        guard let request = nextItem.request else {
            updateQueueItem(
                nextItem,
                status: .FAILED,
                errorMessage: "Invalid request data"
            )
            // Continue processing next item
            if !queueItems.filter({ $0.status == .IN_PROGRESS }).isEmpty {
                await processQueue()
            }
            return
        }
        
        do {
            let adapter = GenerateImageAdapter(
                imageGenerationRequest: request,
                modelContext: context
            )
            
            let response = await adapter.makeRequest()
            
            if response.status == .GENERATED {
                updateQueueItem(
                    nextItem,
                    status: .SUCCESSFUL,
                    response: response,
                    setId: response.set?.id
                )
            } else {
                updateQueueItem(
                    nextItem,
                    status: .FAILED,
                    errorMessage: response.errorMessage ?? "Generation failed"
                )
            }
        } catch {
            updateQueueItem(
                nextItem,
                status: .FAILED,
                errorMessage: error.localizedDescription
            )
        }
        
        // Continue processing next item
        if !queueItems.filter({ $0.status == .IN_PROGRESS }).isEmpty {
            await processQueue()
        }
    }
    
    private func updateQueueItem(
        _ item: QueueItem,
        status: EnumQueueItemStatus,
        response: ImageSetResponse? = nil,
        errorMessage: String? = nil,
        setId: UUID? = nil
    ) {
        guard let context = modelContext else { return }
        
        item.status = status
        item.updatedAt = Date()
        item.response = response
        item.errorMessage = errorMessage
        item.setId = setId
        
        do {
            try context.save()
            // Trigger UI update
            objectWillChange.send()
        } catch {
            print("Failed to update queue item: \(error)")
        }
    }
    
    // MARK: - Data Loading
    
    private func loadQueueItems() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<QueueItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            queueItems = try context.fetch(descriptor)
            
            // Resume processing if there are in-progress items
            if queueItems.contains(where: { $0.status == .IN_PROGRESS }) {
                startProcessing()
            }
        } catch {
            print("Failed to load queue items: \(error)")
            queueItems = []
        }
    }
    
    // MARK: - Cleanup
    
    private func startCleanupTimer() {
        // Run cleanup every minute
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.cleanupOldFailedItems()
            }
        }
    }
    
    private func cleanupOldFailedItems() {
        let fiveMinutesAgo = Date().addingTimeInterval(-5 * 60)
        let oldFailedItems = queueItems.filter {
            $0.status == .FAILED && $0.updatedAt < fiveMinutesAgo
        }
        
        oldFailedItems.forEach { removeFromQueue($0) }
    }
    
    deinit {
        cleanupTimer?.invalidate()
        processingTask?.cancel()
    }
}
