import SwiftData
import CloudKit
import SwiftUI

enum EnumArtVariant: String, Codable, CaseIterable, Identifiable {
    var id : String { UUID().uuidString }
    
    case NORMAL = "Normal"
    case WATERCOLOR = "Watercolor"
    case OIL_PAINTING = "Oil Painting"
    case SKETCH = "Sketch"
    case CARTOON = "Cartoon"
    case PIXEL_ART = "Pixel Art"
    case CHARCOAL = "Charcoal"
    case ACRYLIC = "Acrylic"
    case PASTEL = "Pastel"
    case INK = "Ink"
    case GRAFFITI = "Graffiti"
    case ABSTRACT = "Abstract"
    case DIGITAL_ART = "Digital Art"
    case IMPRESSIONISM = "Impressionism"
    case SURREALISM = "Surrealism"
    case MINIMALISM = "Minimalism"
    case PHOTOREALISM = "Photorealism"
    case LINE_ART = "Line Art"
    case SCULPTURE = "Sculpture"
    case ANIME = "Anime"
    case COMIC_BOOK = "Comic Book"
    case FANTASY_ART = "Fantasy Art"
    case ANALOG_FILM = "Analog Film"
    case NEON_PUNK = "Neon Punk"
    case ISOMETRIC = "Isometric"
    case ORIGAMI = "Origami"
    case MODEL_3D = "3D Model"
    case CINEMATIC = "Cinematic"
    case TILE_TEXTURE = "Tile Texture"
  }

enum EnumArtStyle: String, Codable, CaseIterable, Identifiable {
    var id : String { UUID().uuidString }
    
    case NATURAL = "Natural"
    case VIVID = "Vivid"
}

enum EnumArtQuality: String, Codable, CaseIterable, Identifiable {
    var id : String { UUID().uuidString }
    
    case HD = "HD"
    case STANDARD = "Standard"
}

enum EnumGenerationStatus: String, Codable, CaseIterable, Identifiable {
    var id : String { UUID().uuidString }
    
    case GENERATED
    case FAILED
}

enum EnumGenerationContentType: String, Codable, CaseIterable, Identifiable {
    var id : String { UUID().uuidString }
    
    case IMAGE_2D
    case VIDEO
    case IMAGE_3D
}

@Model
class Generation: Identifiable, Codable {
    enum CodingKeys: CodingKey {
        case id
        case setId
        case createdAt
        case modelId
        case prompt
        case promptEnhanceOpted
        case promptAfterEnhance
        case artStyle
        case artVariant
        case artQuality
        case artDimensions
        case size
        case creditUsed
        case status
        case colorPalette
        case modelRevisedPrompt
        case clientImage
        case clientMask
        case negativePrompt
        case searchPrompt
        case contentType
    }
    
    var id: UUID = UUID()
    var setId: UUID = UUID()
    var createdAt: Date = Date()
    var modelId: String = ""
    var prompt: String = ""
    var promptEnhanceOpted: Bool = false
    var promptAfterEnhance: String = ""
    var artStyle: EnumArtStyle = EnumArtStyle.VIVID
    var artVariant: EnumArtVariant = EnumArtVariant.NORMAL
    var artQuality: EnumArtQuality = EnumArtQuality.HD
    var artDimensions: String = "1024x1024"
    var size: Int = 0
    var creditUsed: Double = 0
    var status: EnumGenerationStatus = EnumGenerationStatus.GENERATED
    var colorPalette: [String] = []
    var modelRevisedPrompt: String? = nil
    var clientImage: String? = nil
    var clientMask: String? = nil
    var negativePrompt: String? = nil
    var searchPrompt: String? = nil
    var contentType: EnumGenerationContentType = EnumGenerationContentType.IMAGE_2D

    init(id: UUID, setId: UUID, modelId: String, prompt: String, promptEnhanceOpted: Bool, promptAfterEnhance: String, artStyle: EnumArtStyle = EnumArtStyle.NATURAL, artVariant: EnumArtVariant = EnumArtVariant.NORMAL, artQuality: EnumArtQuality = EnumArtQuality.HD, artDimensions: String, size: Int, creditUsed: Double, status: EnumGenerationStatus, colorPalette: [String], modelRevisedPrompt: String? = nil, clientImage: String? = nil, clientMask: String? = nil, negativePrompt: String? = nil, searchPrompt: String? = nil, contentType: EnumGenerationContentType = EnumGenerationContentType.IMAGE_2D
    ) {
        self.id = id
        self.setId = setId
        self.createdAt = Date()
        self.modelId = modelId
        self.prompt = prompt
        self.promptEnhanceOpted = promptEnhanceOpted
        self.promptAfterEnhance = promptAfterEnhance
        self.artStyle = artStyle
        self.artVariant = artVariant
        self.artQuality = artQuality
        self.artDimensions = artDimensions
        self.size = size
        self.creditUsed = creditUsed
        self.status = status
        self.colorPalette = colorPalette
        self.modelRevisedPrompt = modelRevisedPrompt
        self.clientImage = clientImage
        self.clientMask = clientMask
        self.negativePrompt = negativePrompt
        self.searchPrompt = searchPrompt
        self.contentType = contentType
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        setId = try container.decode(UUID.self, forKey: .setId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        modelId = try container.decode(String.self, forKey: .modelId)
        prompt = try container.decode(String.self, forKey: .prompt)
        promptEnhanceOpted = try container.decode(Bool.self, forKey: .promptEnhanceOpted)
        promptAfterEnhance = try container.decode(String.self, forKey: .promptAfterEnhance)
        artStyle = try container.decode(EnumArtStyle.self, forKey: .artStyle)
        artVariant = try container.decode(EnumArtVariant.self, forKey: .artVariant)
        artQuality = try container.decode(EnumArtQuality.self, forKey: .artQuality)
        artDimensions = try container.decode(String.self, forKey: .artDimensions)
        size = try container.decode(Int.self, forKey: .size)
        creditUsed = try container.decode(Double.self, forKey: .creditUsed)
        status = try container.decode(EnumGenerationStatus.self, forKey: .status)
        colorPalette = try container.decode([String].self, forKey: .colorPalette)
        modelRevisedPrompt = try container.decodeIfPresent(String.self, forKey: .modelRevisedPrompt)
        clientImage = try container.decodeIfPresent(String.self, forKey: .clientImage)
        clientMask = try container.decodeIfPresent(String.self, forKey: .clientMask)
        negativePrompt = try container.decodeIfPresent(String.self, forKey: .negativePrompt)
        searchPrompt = try container.decodeIfPresent(String.self, forKey: .searchPrompt)
        contentType = try container.decode(EnumGenerationContentType.self, forKey: .contentType)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(setId, forKey: .setId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(modelId, forKey: .modelId)
        try container.encode(prompt, forKey: .prompt)
        try container.encode(promptEnhanceOpted, forKey: .promptEnhanceOpted)
        try container.encode(promptAfterEnhance, forKey: .promptAfterEnhance)
        try container.encode(artStyle, forKey: .artStyle)
        try container.encode(artVariant, forKey: .artVariant)
        try container.encode(artQuality, forKey: .artQuality)
        try container.encode(artDimensions, forKey: .artDimensions)
        try container.encode(size, forKey: .size)
        try container.encode(creditUsed, forKey: .creditUsed)
        try container.encode(status, forKey: .status)
        try container.encode(colorPalette, forKey: .colorPalette)
        try container.encodeIfPresent(modelRevisedPrompt, forKey: .modelRevisedPrompt)
        try container.encodeIfPresent(clientImage, forKey: .clientImage)
        try container.encodeIfPresent(clientMask, forKey: .clientMask)
        try container.encodeIfPresent(negativePrompt, forKey: .negativePrompt)
        try container.encodeIfPresent(searchPrompt, forKey: .searchPrompt)
        try container.encode(contentType, forKey: .contentType)
    }
}
