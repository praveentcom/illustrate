# Queue System Flow Diagram

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Interface                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐                    ┌──────────────────┐   │
│  │  Generate Form   │                    │  Queue Sidebar   │   │
│  │                  │                    │                  │   │
│  │  [Prompt Input]  │                    │  ┌────────────┐ │   │
│  │  [Parameters]    │                    │  │ Item 1: ⏱  │ │   │
│  │                  │                    │  ├────────────┤ │   │
│  │  [Generate] ──┐  │                    │  │ Item 2: ✅ │←┼───┼─ Click to view
│  └────────────────┘ │                    │  ├────────────┤ │   │
│                     │                    │  │ Item 3: ❌ │ │   │
│                     │                    │  └────────────┘ │   │
│                     │                    └──────────────────┘   │
└─────────────────────┼──────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│              GenerationQueueService (@MainActor)                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. addToQueue()                                                 │
│     └─> Create QueueItem                                         │
│     └─> Save to SwiftData                                        │
│     └─> Start processing                                         │
│                                                                   │
│  2. processQueue() [async]                                       │
│     └─> Get next IN_PROGRESS item (FIFO)                        │
│     └─> Call GenerateImageAdapter                               │
│     └─> Update status (SUCCESSFUL/FAILED)                       │
│     └─> Continue to next item                                    │
│                                                                   │
│  3. cleanupOldFailedItems() [timer]                             │
│     └─> Remove items > 5 minutes old                            │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                      SwiftData Storage                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  QueueItem {                                                     │
│    id, createdAt, updatedAt                                      │
│    status: IN_PROGRESS | SUCCESSFUL | FAILED                    │
│    request: ImageGenerationRequest                              │
│    response: ImageSetResponse?                                  │
│    errorMessage: String?                                         │
│    setId: UUID?                                                  │
│  }                                                               │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## User Flow Sequence

```
User                 UI                  Service              Adapter           Storage
 │                   │                     │                    │                 │
 │  Fill form        │                     │                    │                 │
 ├──────────────────>│                     │                    │                 │
 │                   │                     │                    │                 │
 │  Click Generate   │                     │                    │                 │
 ├──────────────────>│  addToQueue()       │                    │                 │
 │                   ├────────────────────>│  Save QueueItem    │                 │
 │                   │                     ├───────────────────────────────────────>│
 │                   │                     │                    │                 │
 │  ✅ Toast shown   │                     │  processQueue()    │                 │
 │<──────────────────┤                     │  (async)           │                 │
 │                   │                     │                    │                 │
 │  Navigate away    │                     │  makeRequest()     │                 │
 ├──────────────────>│                     ├───────────────────>│                 │
 │                   │                     │                    │  Call API       │
 │  Use app freely   │                     │                    ├─────────> ☁️    │
 │<─────────────────>│                     │                    │                 │
 │                   │                     │                    │  Response       │
 │                   │  Update status      │                    │<──────────      │
 │                   │<────────────────────┤<───────────────────┤                 │
 │                   │                     │  Save result       │                 │
 │  View queue       │                     ├───────────────────────────────────────>│
 ├──────────────────>│                     │                    │                 │
 │                   │                     │                    │                 │
 │  ✅ Item shows    │  Fetch QueueItems   │                    │                 │
 │<──────────────────┤<───────────────────────────────────────────────────────────┤
 │                   │                     │                    │                 │
 │  Click item       │  Navigate to result │                    │                 │
 ├──────────────────>├────────────────────>│                    │                 │
 │                   │                     │                    │                 │
 │  View generation  │                     │                    │                 │
 │<──────────────────┤                     │                    │                 │
```

## State Transitions

```
                    ┌─────────────────┐
                    │                 │
                    │   SUBMITTED     │
                    │                 │
                    └────────┬────────┘
                             │
                             │ addToQueue()
                             ▼
                    ┌─────────────────┐
                    │                 │
              ┌────>│  IN_PROGRESS    │
              │     │                 │
              │     └────────┬────────┘
              │              │
              │              │ processQueue()
              │              ▼
              │     ┌─────────────────┐
              │     │   Processing    │
              │     │   with Adapter  │
              │     └────────┬────────┘
              │              │
              │              │
              │     ┌────────┴────────┐
              │     │                 │
              │     ▼                 ▼
       ┌──────┴──────────┐   ┌─────────────────┐
       │                 │   │                 │
       │   SUCCESSFUL    │   │     FAILED      │
       │                 │   │                 │
       └────────┬────────┘   └────────┬────────┘
                │                     │
                │                     │ After 5 min
                │                     ▼
                │            ┌─────────────────┐
                │            │                 │
                │            │   AUTO-REMOVED  │
                │            │                 │
                │            └─────────────────┘
                │
                │ User clicks
                ▼
       ┌─────────────────┐
       │                 │
       │  View Result    │
       │                 │
       └─────────────────┘
```

## Queue Processing Logic

```python
# Pseudo-code for queue processing

async function processQueue():
    if no modelContext:
        return
    
    # Get next item in FIFO order
    nextItem = queueItems
        .filter(status == IN_PROGRESS)
        .sortBy(createdAt, ascending)
        .first
    
    if not nextItem:
        return  # Queue is empty
    
    if not nextItem.request:
        # Invalid request
        updateQueueItem(nextItem, FAILED, "Invalid request data")
        processQueue()  # Continue to next
        return
    
    try:
        # Call adapter to generate
        adapter = GenerateImageAdapter(nextItem.request, modelContext)
        response = await adapter.makeRequest()
        
        if response.status == GENERATED:
            updateQueueItem(nextItem, SUCCESSFUL, response)
        else:
            updateQueueItem(nextItem, FAILED, response.errorMessage)
    
    catch error:
        updateQueueItem(nextItem, FAILED, error.message)
    
    # Process next item if any
    if hasMoreInProgressItems():
        processQueue()
```

## Timer Cleanup Logic

```python
# Pseudo-code for auto-cleanup

function cleanupOldFailedItems():
    fiveMinutesAgo = Date.now() - (5 * 60 * 1000)
    
    oldFailedItems = queueItems.filter(
        item.status == FAILED && 
        item.updatedAt < fiveMinutesAgo
    )
    
    for item in oldFailedItems:
        removeFromQueue(item)

# Timer runs every 60 seconds
Timer.repeat(60 seconds):
    cleanupOldFailedItems()
```

## Thread Safety

```
Main Thread (@MainActor)
├── UI Updates
├── State Changes
├── Queue Service Operations
│   ├── addToQueue()
│   ├── removeFromQueue()
│   ├── updateQueueItem()
│   └── cleanupOldFailedItems()
└── processQueue() (async but @MainActor)

Background (Adapter)
└── API Calls
    └── Network Requests
```

## Data Flow

```
Generate Form ──┐
                │
                ├─> ImageGenerationRequest
                │   ├── modelId
                │   ├── prompt
                │   ├── parameters
                │   └── connectionSecret
                │
                ▼
        GenerationQueueService
                │
                ├─> QueueItem (SwiftData)
                │   ├── id
                │   ├── status
                │   ├── request
                │   ├── response
                │   └── setId
                │
                ▼
        GenerateImageAdapter
                │
                ├─> API Service (OpenAI, Stability, etc.)
                │
                ▼
        ImageSetResponse
                │
                ├── ImageSet (SwiftData)
                │   ├── id
                │   ├── prompt
                │   └── metadata
                │
                └── Generation (SwiftData)
                    ├── id
                    ├── base64 image
                    └── metadata
```

## Key Design Principles

1. **Non-Blocking**: UI never waits for generation
2. **FIFO**: First In, First Out processing order
3. **Sequential**: One item at a time
4. **Persistent**: Survives app restarts
5. **Observable**: Real-time UI updates
6. **Safe**: @MainActor ensures thread safety
7. **Clean**: Auto-removes old failures
8. **Navigable**: Click to view results
