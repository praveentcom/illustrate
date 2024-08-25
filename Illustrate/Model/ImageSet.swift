import SwiftData
import CloudKit
import SwiftUI

enum EnumSetType: String, Codable, CaseIterable, Identifiable {
    var id : String { UUID().uuidString }
    
    case GENERATE
    case EDIT_UPSCALE
    case EDIT_EXPAND
    case EDIT_PROMPT
    case EDIT_MASK
    case EDIT_MASK_ERASE
    case EDIT_REPLACE
    case REMOVE_BACKGROUND
    case VIDEO_IMAGE
}

func labelForSetType(_ item: EnumSetType) -> String {
    switch item {
    case .GENERATE:
        return "Generate Image"
    case .EDIT_UPSCALE:
        return "Upscale Image"
    case .EDIT_EXPAND:
        return "Expand Image"
    case .EDIT_PROMPT:
        return "Edit with Prompt"
    case .EDIT_MASK:
        return "Edit with Mask"
    case .EDIT_MASK_ERASE:
        return "Erase with Mask"
    case .EDIT_REPLACE:
        return "Search & Replace"
    case .REMOVE_BACKGROUND:
        return "Remove Background"
    case .VIDEO_IMAGE:
        return "Image to Video"
    }
}

func subLabelForSetType(_ item: EnumSetType) -> String {
    switch item {
    case .GENERATE:
        return "Imagine an image and generate in seconds"
    case .EDIT_UPSCALE:
        return "Upload low-res image and upscale details"
    case .EDIT_EXPAND:
        return "Expand image across any side with your prompt"
    case .EDIT_PROMPT:
        return "Edit an existing image with simple prompt"
    case .EDIT_MASK:
        return "Edit an existing image by drawing a mask"
    case .EDIT_MASK_ERASE:
        return "Erase objects in an image by drawing a mask"
    case .EDIT_REPLACE:
        return "Search objects with a prompt and replace with another"
    case .REMOVE_BACKGROUND:
        return "Simply remove the background from an image"
    case .VIDEO_IMAGE:
        return "Convert an image to a video with your prompt"
    }
}

func iconForSetType(_ item: EnumSetType) -> String {
    switch item {
    case .GENERATE:
        return "paintbrush"
    case .EDIT_UPSCALE:
        return "arrow.up.forward.app"
    case .EDIT_EXPAND:
        return "arrow.up.left.and.arrow.down.right"
    case .EDIT_PROMPT:
        return "character.cursor.ibeam"
    case .EDIT_MASK:
        return "pencil.and.outline"
    case .EDIT_MASK_ERASE:
        return "eraser"
    case .EDIT_REPLACE:
        return "magnifyingglass"
    case .REMOVE_BACKGROUND:
        return "scissors"
    case .VIDEO_IMAGE:
        return "video"
    }
}

func setTypeForItem(_ item: EnumNavigationItem) -> EnumSetType {
    switch item {
    case .generateGenerate:
        return .GENERATE
    case .generateEditUpscale:
        return .EDIT_UPSCALE
    case .generateEditExpand:
        return .EDIT_EXPAND
    case .generateEditPrompt:
        return .EDIT_PROMPT
    case .generateEditMask:
        return .EDIT_MASK
    case .generateEraseMask:
        return .EDIT_MASK_ERASE
    case .generateSearchReplace:
        return .EDIT_REPLACE
    case .generateRemoveBackground:
        return .REMOVE_BACKGROUND
    case .generateVideoImage:
        return .VIDEO_IMAGE
    default:
        return .GENERATE
    }
}

@Model
class ImageSet: Identifiable, Codable {
    enum CodingKeys: CodingKey {
        case id
        case createdAt
        case prompt
        case starred
        case modelId
        case artStyle
        case artVariant
        case artDimensions
        case setType
        case negativePrompt
        case searchPrompt
    }
    
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var prompt: String = ""
    var starred: Bool = false
    var modelId: String = ""
    var artStyle: EnumArtStyle = EnumArtStyle.NATURAL
    var artVariant: EnumArtVariant = EnumArtVariant.NORMAL
    var artDimensions: String = "1024x1024"
    var setType: EnumSetType = EnumSetType.GENERATE
    var negativePrompt: String? = nil
    var searchPrompt: String? = nil

    init(prompt: String, modelId: String, artStyle: EnumArtStyle = EnumArtStyle.NATURAL, artVariant: EnumArtVariant = EnumArtVariant.NORMAL, artDimensions: String, setType: EnumSetType, negativePrompt: String? = nil, searchPrompt: String? = nil) {
        self.id = UUID()
        self.createdAt = Date()
        self.prompt = prompt
        self.starred = false
        self.modelId = modelId
        self.artStyle = artStyle
        self.artVariant = artVariant
        self.artDimensions = artDimensions
        self.setType = setType
        self.negativePrompt = negativePrompt
        self.searchPrompt = searchPrompt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        prompt = try container.decode(String.self, forKey: .prompt)
        starred = try container.decode(Bool.self, forKey: .starred)
        modelId = try container.decode(String.self, forKey: .modelId)
        artStyle = try container.decode(EnumArtStyle.self, forKey: .artStyle)
        artVariant = try container.decode(EnumArtVariant.self, forKey: .artVariant)
        artDimensions = try container.decode(String.self, forKey: .artDimensions)
        setType = try container.decode(EnumSetType.self, forKey: .setType)
        negativePrompt = try container.decodeIfPresent(String.self, forKey: .negativePrompt)
        searchPrompt = try container.decodeIfPresent(String.self, forKey: .searchPrompt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(prompt, forKey: .prompt)
        try container.encode(starred, forKey: .starred)
        try container.encode(modelId, forKey: .modelId)
        try container.encode(artStyle, forKey: .artStyle)
        try container.encode(artVariant, forKey: .artVariant)
        try container.encode(artDimensions, forKey: .artDimensions)
        try container.encode(setType, forKey: .setType)
        try container.encode(negativePrompt, forKey: .negativePrompt)
        try container.encode(searchPrompt, forKey: .searchPrompt)
    }
}
