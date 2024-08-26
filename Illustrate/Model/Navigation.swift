import SwiftUI
import Foundation

enum EnumNavigationItem: Identifiable, Hashable {
    // Primary Views
    case dashboardWorkspace
    
    case generateGenerate
    case generateEditUpscale
    case generateEditExpand
    case generateEditPrompt
    case generateEditMask
    case generateEraseMask
    case generateSearchReplace
    case generateRemoveBackground
    
    case generateVideoImage
    
    case historyRequests
    case historyImageGallery
    case historyVideoGallery
    
    case settingsConnections
    case settingsManageStorage
    
    // Secondary Views
    case generationImage(setId: UUID)
    case generationVideo(setId: UUID)
    
    // Enum Meta
    var id: String {
        switch self {
        case .generationImage(let setId):
            return "generationImage-\(setId.uuidString)"
        case .generationVideo(let setId):
            return "generationVideo-\(setId.uuidString)"
        default:
            return "\(self)"
        }
    }
}

enum EnumNavigationSection: String, Codable, CaseIterable, Identifiable {
    var id : String { UUID().uuidString }
    
    case Dashboard = "Dashboard"
    case ImageGenerations = "Image Generations"
    case VideoGenerations = "Video Generations"
    case History = "History"
    case Settings = "Settings"
}

func sectionItems(section: EnumNavigationSection) -> [EnumNavigationItem] {
    switch section {
    case .Dashboard:
        return [.dashboardWorkspace]
    case .ImageGenerations:
        return [.generateGenerate, .generateEditUpscale, .generateEditExpand, .generateEditPrompt, .generateEditMask, .generateEraseMask, .generateSearchReplace, .generateRemoveBackground]
    case .VideoGenerations:
        return [.generateVideoImage]
    case .History:
        #if os(macOS)
        return [.historyRequests, .historyImageGallery, .historyVideoGallery]
        #else
        return [.historyImageGallery, .historyVideoGallery]
        #endif
    case .Settings:
        return [.settingsConnections, .settingsManageStorage]
    }
}

func labelForItem(_ item: EnumNavigationItem) -> String {
    switch item {
    case .dashboardWorkspace:
        return "Workspace"
    case .generateGenerate:
        return labelForSetType(.GENERATE)
    case .generateEditUpscale:
        return labelForSetType(.EDIT_UPSCALE)
    case .generateEditExpand:
        return labelForSetType(.EDIT_EXPAND)
    case .generateEditPrompt:
        return labelForSetType(.EDIT_PROMPT)
    case .generateEditMask:
        return labelForSetType(.EDIT_MASK)
    case .generateEraseMask:
        return labelForSetType(.EDIT_MASK_ERASE)
    case .generateSearchReplace:
        return labelForSetType(.EDIT_REPLACE)
    case .generateRemoveBackground:
        return labelForSetType(.REMOVE_BACKGROUND)
    case .generateVideoImage:
        return labelForSetType(.VIDEO_IMAGE)
    case .historyRequests:
        return "All Requests"
    case .historyImageGallery:
        return "Image Gallery"
    case .historyVideoGallery:
        return "Video Gallery"
    case .settingsConnections:
        return "Manage Connections"
    case .settingsManageStorage:
        return "Manage Storage"
    case .generationImage:
        return "Image Generation"
    case .generationVideo:
        return "Video Generation"
    }
}

func subLabelForItem(_ item: EnumNavigationItem) -> String {
    switch item {
    case .dashboardWorkspace:
        return "Your go-to workplace dashboard"
    case .generateGenerate:
        return subLabelForSetType(.GENERATE)
    case .generateEditUpscale:
        return subLabelForSetType(.EDIT_UPSCALE)
    case .generateEditExpand:
        return subLabelForSetType(.EDIT_EXPAND)
    case .generateEditPrompt:
        return subLabelForSetType(.EDIT_PROMPT)
    case .generateEditMask:
        return subLabelForSetType(.EDIT_MASK)
    case .generateEraseMask:
        return subLabelForSetType(.EDIT_MASK_ERASE)
    case .generateSearchReplace:
        return subLabelForSetType(.EDIT_REPLACE)
    case .generateRemoveBackground:
        return subLabelForSetType(.REMOVE_BACKGROUND)
    case .generateVideoImage:
        return subLabelForSetType(.VIDEO_IMAGE)
    case .historyRequests:
        return "View all your generation requests"
    case .historyImageGallery:
        return "Gallery for your generated images"
    case .historyVideoGallery:
        return "Gallery for your generated videos"
    case .settingsConnections:
        return "Link and manage your connections"
    case .settingsManageStorage:
        return "Clear your Illustrate iCloud storage"
    case .generationImage:
        return "View the generated image"
    case .generationVideo:
        return "View the generated video"
    }
}

func iconForItem(_ item: EnumNavigationItem) -> String {
    switch item {
    case .dashboardWorkspace:
        return "house"
    case .generateGenerate:
        return iconForSetType(.GENERATE)
    case .generateEditUpscale:
        return iconForSetType(.EDIT_UPSCALE)
    case .generateEditExpand:
        return iconForSetType(.EDIT_EXPAND)
    case .generateEditPrompt:
        return iconForSetType(.EDIT_PROMPT)
    case .generateEditMask:
        return iconForSetType(.EDIT_MASK)
    case .generateEraseMask:
        return iconForSetType(.EDIT_MASK_ERASE)
    case .generateSearchReplace:
        return iconForSetType(.EDIT_REPLACE)
    case .generateRemoveBackground:
        return iconForSetType(.REMOVE_BACKGROUND)
    case .generateVideoImage:
        return iconForSetType(.VIDEO_IMAGE)
    case .historyRequests:
        return "note.text"
    case .historyImageGallery:
        return "photo"
    case .historyVideoGallery:
        return "film"
    case .settingsConnections:
        return "link"
    case .settingsManageStorage:
        return "trash"
    case .generationImage:
        return "paintbrush"
    case .generationVideo:
        return "video"
    }
}

@ViewBuilder
func viewForItem(_ item: EnumNavigationItem) -> some View {
    switch item {
    case .dashboardWorkspace:
        WorkspaceView()
    case .generateGenerate:
        GenerateImageView()
    case .generateEditUpscale:
        EditUpscaleImageView()
    case .generateEditExpand:
        EditExpandImageView()
    case .generateEditPrompt:
        EditPromptImageView()
    case .generateEditMask:
        EditMaskImageView()
    case .generateEraseMask:
        EraseMaskImageView()
    case .generateSearchReplace:
        SearchReplaceImageView()
    case .generateRemoveBackground:
        RemoveBackgroundImageView()
    case .generateVideoImage:
        ImageToVideoView()
    case .historyRequests:
        RequestsView()
    case .historyImageGallery:
        GalleryImageView()
    case .historyVideoGallery:
        GalleryVideoView()
    case .settingsConnections:
        ConnectionsView()
    case .settingsManageStorage:
        ManageStorageView()
    case .generationImage(let setId):
        GenerationImageView(setId: setId)
    case .generationVideo(let setId):
        GenerationVideoView(setId: setId)
    }
}
