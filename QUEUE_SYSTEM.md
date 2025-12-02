# Queue System Documentation

## Overview
The queue system allows users to submit image generation requests without blocking the UI. Users can navigate through the application and submit multiple requests while generations are processed in the background.

## Components

### 1. QueueItem Model (`Illustrate/Model/QueueItem.swift`)
- Represents a single generation request in the queue
- Contains three states: `IN_PROGRESS`, `SUCCESSFUL`, `FAILED`
- Stores request parameters and response data
- Persisted using SwiftData

### 2. GenerationQueueService (`Illustrate/Services/GenerationQueueService.swift`)
- Singleton service managing the generation queue
- Processes queue items sequentially in the background
- Auto-cleanup: Failed requests are removed after 5 minutes
- Thread-safe using `@MainActor`

### 3. QueueSidebarView (`Illustrate/Components/Queue/QueueSidebarView.swift`)
- Desktop UI for viewing queue status
- Displays queue items with their status
- Allows clicking on successful items to view results
- Provides clear options for successful/failed items

### 4. MobileQueueView (`Illustrate/View/Navigation/MobileView.swift`)
- Mobile UI for viewing queue (presented as a sheet)
- Badge indicator showing active queue items
- Similar functionality to desktop sidebar

## User Flow

### Submitting a Generation Request
1. User fills in generation parameters (prompt, dimensions, etc.)
2. Clicks "Generate" button
3. Request is added to queue immediately
4. User sees confirmation toast
5. User can continue using the app or submit more requests

### Viewing Queue Status
**Desktop:**
- Queue sidebar is visible on the right side (toggle with toolbar button)
- Shows all queued items with status indicators

**Mobile:**
- Queue icon in navigation bar (with badge if items exist)
- Tap icon to open queue sheet

### Viewing Results
1. Queue item shows green checkmark when complete
2. Click/tap on completed item
3. Opens GenerationImageView or GenerationVideoView with results

### Auto-Cleanup
- Failed requests are automatically removed after 5 minutes
- Users can manually clear successful or failed items

## Architecture Decisions

### Non-Blocking Design
- All generation happens asynchronously in background tasks
- UI remains responsive during generation
- Multiple requests can be queued simultaneously

### Sequential Processing
- Queue processes one item at a time
- Ensures stable resource usage
- Prevents API rate limiting issues

### State Management
- Queue state managed by ObservableObject service
- UI updates automatically via @Published properties
- SwiftData ensures persistence across app launches

## Integration Points

### GenerateImageView
- Updated to use queue instead of blocking UI
- Removed `isGenerating` state
- Clears form after successful submission

### Other Generation Views
Currently, other generation views (upscale, mask, video) still use the blocking approach. These can be updated similarly in the future.

## Future Enhancements

1. **Priority Queue**: Allow users to prioritize certain requests
2. **Pause/Resume**: Enable pausing queue processing
3. **Retry Failed**: Add retry option for failed requests
4. **Notifications**: Push notifications when generation completes
5. **Batch Operations**: Support for bulk actions on queue items
6. **Queue Analytics**: Track queue performance metrics
