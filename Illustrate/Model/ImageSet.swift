import SwiftData
import CloudKit
import SwiftUI

enum EnumSetType: String, Codable, CaseIterable, Identifiable {
    var id : String { UUID().uuidString }
    
    case GENERATE = "Generate Image"
    case EDIT_UPSCALE = "Upscale Image"
    case EDIT_EXPAND = "Expand Image"
    case EDIT_MASK = "Edit with Mask"
    case EDIT_MASK_ERASE = "Erase with Mask"
    case EDIT_REPLACE = "Search and Replace"
    case REMOVE_BACKGROUND = "Remove Background"
    case VIDEO_IMAGE = "Image to Video"
}

func getSetTypeInfo(setType: EnumSetType) -> (label: String, iconString: String) {
    switch setType {
    case .GENERATE:
        return ("Generate Image", "paintbrush")
    case .EDIT_UPSCALE:
        return ("Upscale Image", "arrow.up.forward.app")
    case .EDIT_EXPAND:
        return ("Expand Image", "arrow.up.left.and.arrow.down.right")
    case .EDIT_MASK:
        return ("Edit with Mask", "pencil.and.scribble")
    case .EDIT_MASK_ERASE:
        return ("Erase with Mask", "eraser.line.dashed")
    case .EDIT_REPLACE:
        return ("Search and Replace", "lasso")
    case .REMOVE_BACKGROUND:
        return ("Remove Background", "person.and.background.dotted")
    case .VIDEO_IMAGE:
        return ("Image to Video", "movieclapper")
    }
}

struct NavigationSectionForImageGenerations: View {
    var body: some View {
        Section("Generate Images") {
            NavigationLink(destination: GenerateImageView()) {
                Label(getSetTypeInfo(setType: .GENERATE).label, systemImage: getSetTypeInfo(setType: .GENERATE).iconString)
            }
            NavigationLink(destination: EditUpscaleImageView()) {
                Label(getSetTypeInfo(setType: .EDIT_UPSCALE).label, systemImage: getSetTypeInfo(setType: .EDIT_UPSCALE).iconString)
            }
            NavigationLink(destination: EditExpandImageView()) {
                Label(getSetTypeInfo(setType: .EDIT_EXPAND).label, systemImage: getSetTypeInfo(setType: .EDIT_EXPAND).iconString)
            }
            NavigationLink(destination: EditMaskImageView()) {
                Label(getSetTypeInfo(setType: .EDIT_MASK).label, systemImage: getSetTypeInfo(setType: .EDIT_MASK).iconString)
            }
            NavigationLink(destination: EraseMaskImageView()) {
                Label(getSetTypeInfo(setType: .EDIT_MASK_ERASE).label, systemImage: getSetTypeInfo(setType: .EDIT_MASK_ERASE).iconString)
            }
            NavigationLink(destination: SearchReplaceImageView()) {
                Label(getSetTypeInfo(setType: .EDIT_REPLACE).label, systemImage: getSetTypeInfo(setType: .EDIT_REPLACE).iconString)
            }
            NavigationLink(destination: RemoveBackgroundImageView()) {
                Label(getSetTypeInfo(setType: .REMOVE_BACKGROUND).label, systemImage: getSetTypeInfo(setType: .REMOVE_BACKGROUND).iconString)
            }
        }
    }
}

struct NavigationSectionForVideoGenerations: View {
    var body: some View {
        Section("Generate Videos") {
            NavigationLink(destination: ImageToVideoView()) {
                Label(getSetTypeInfo(setType: .VIDEO_IMAGE).label, systemImage: getSetTypeInfo(setType: .VIDEO_IMAGE).iconString)
            }
        }
    }
}

struct NavigationSectionForGenerationHistory: View {
    var body: some View {
        Section ("History") {
            NavigationLink(destination: RequestsView()) {
                Label("All Requests", systemImage: "note.text")
            }
            NavigationLink(destination: GalleryImageView()) {
                Label("Image Gallery", systemImage: "photo")
            }
            NavigationLink(destination: GalleryVideoView()) {
                Label("Video Gallery", systemImage: "movieclapper")
            }
        }
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
    var prompt: String
    var starred: Bool = false
    var modelId: String
    var artStyle: EnumArtStyle = EnumArtStyle.NATURAL
    var artVariant: EnumArtVariant = EnumArtVariant.NORMAL
    var artDimensions: String
    var setType: EnumSetType = EnumSetType.GENERATE
    var negativePrompt: String?
    var searchPrompt: String?

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
