import Foundation
import SwiftUI

enum EnumNavigationItem: Identifiable, Hashable {
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
    case generateVideoText
    case generateVideoEdit

    case historyRequests
    case historyImageGallery
    case historyVideoGallery
    case historyUsageMetrics

    case settingsProviders
    case settingsManageStorage

    case generationImage(setId: UUID)
    case generationVideo(setId: UUID)

    case addProvider(providerId: UUID)

    var id: String {
        switch self {
        case let .generationImage(setId):
            return "generationImage-\(setId.uuidString)"
        case let .generationVideo(setId):
            return "generationVideo-\(setId.uuidString)"
        case let .addProvider(providerId):
            return "addProvider-\(providerId.uuidString)"
        default:
            return "\(self)"
        }
    }
}

enum EnumNavigationSection: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case Dashboard
    case ImageGenerations = "Image Generations"
    case VideoGenerations = "Video Generations"
    case History
    case Settings
}

func sectionItems(section: EnumNavigationSection) -> [EnumNavigationItem] {
    switch section {
    case .Dashboard:
        return [.dashboardWorkspace]
    case .ImageGenerations:
        return [.generateGenerate, .generateEditUpscale, .generateEditExpand, .generateEditPrompt, .generateEditMask, .generateEraseMask, .generateSearchReplace, .generateRemoveBackground]
    case .VideoGenerations:
        return [.generateVideoText, .generateVideoImage, .generateVideoEdit]
    case .History:
        #if os(macOS)
            return [.historyRequests, .historyImageGallery, .historyVideoGallery, .historyUsageMetrics]
        #else
            return [.historyImageGallery, .historyVideoGallery, .historyUsageMetrics]
        #endif
    case .Settings:
        return [.settingsProviders, .settingsManageStorage]
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
    case .generateVideoText:
        return labelForSetType(.VIDEO_TEXT)
    case .generateVideoEdit:
        return labelForSetType(.VIDEO_VIDEO)
    case .historyRequests:
        return "All Requests"
    case .historyImageGallery:
        return "Image Gallery"
    case .historyVideoGallery:
        return "Video Gallery"
    case .historyUsageMetrics:
        return "Usage Metrics"
    case .settingsProviders:
        return "Manage Providers"
    case .settingsManageStorage:
        return "Manage Storage"
    case .generationImage:
        return "Image Generation"
    case .generationVideo:
        return "Video Generation"
    case .addProvider:
        return "Add Provider"
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
    case .generateVideoText:
        return subLabelForSetType(.VIDEO_TEXT)
    case .generateVideoEdit:
        return subLabelForSetType(.VIDEO_VIDEO)
    case .historyRequests:
        return "View all your generation requests"
    case .historyImageGallery:
        return "Gallery for your generated images"
    case .historyVideoGallery:
        return "Gallery for your generated videos"
    case .historyUsageMetrics:
        return "View your generation usage metrics"
    case .settingsProviders:
        return "Link and manage your providers"
    case .settingsManageStorage:
        return "Clear your Illustrate iCloud storage"
    case .generationImage:
        return "View the generated image"
    case .generationVideo:
        return "View the generated video"
    case .addProvider:
        return "Add a new provider"
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
    case .generateVideoText:
        return iconForSetType(.VIDEO_TEXT)
    case .generateVideoEdit:
        return iconForSetType(.VIDEO_VIDEO)
    case .historyRequests:
        return "note.text"
    case .historyImageGallery:
        return "photo.stack"
    case .historyVideoGallery:
        return "film.stack"
    case .historyUsageMetrics:
        return "chart.bar.xaxis"
    case .settingsProviders:
        return "link"
    case .settingsManageStorage:
        return "lock.icloud"
    case .generationImage:
        return "sparkles"
    case .generationVideo:
        return "video"
    case .addProvider:
        return "plus"
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
    case .generateVideoText:
        TextToVideoView()
    case .generateVideoEdit:
        EditVideoView()
    case .historyRequests:
        RequestsView()
    case .historyImageGallery:
        GalleryImageView()
    case .historyVideoGallery:
        GalleryVideoView()
    case .historyUsageMetrics:
        UsageMetricsView()
    case .settingsProviders:
        ProvidersView()
    case .settingsManageStorage:
        ManageStorageView()
    case let .generationImage(setId):
        GenerationImageView(setId: setId)
    case let .generationVideo(setId):
        GenerationVideoView(setId: setId)
    case let .addProvider(providerId):
        AddProviderView(providerId: providerId)
    }
}
