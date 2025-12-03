import Foundation
import SwiftUI

struct CostEstimator {
    
    static func getCreditsUsed(request: ImageGenerationRequest) -> Double {
        guard let model = ConnectionService.shared.model(by: request.modelId) else {
            return 0.0
        }
        return estimatedImageCost(
            modelCode: model.modelCode,
            quality: request.artQuality,
            dimensions: request.artDimensions,
            numberOfImages: request.numberOfImages
        )
    }
    
    static func getCreditsUsed(request: VideoGenerationRequest) -> Double {
        guard let model = ConnectionService.shared.model(by: request.modelId) else {
            return 0.0
        }
        return estimatedVideoCost(
            modelCode: model.modelCode,
            durationSeconds: request.durationSeconds ?? 8,
            numberOfVideos: request.numberOfVideos,
            dimensions: request.artDimensions
        )
    }
    
    static func estimatedImageCost(
        modelCode: EnumConnectionModelCode,
        quality: EnumArtQuality = EnumArtQuality.STANDARD,
        dimensions: String = "1024x1024",
        numberOfImages: Int = 1
    ) -> Double {
        let baseCost: Double
        
        switch modelCode {
        case .OPENAI_DALLE3:
            baseCost = OpenAIDallE3Cost(quality: quality, dimensions: dimensions)
        case .OPENAI_GPT_IMAGE_1, .OPENAI_GPT_IMAGE_1_EDIT:
            baseCost = quality == .HD ? 0.17 : 0.04
        case .OPENAI_SORA_2:
            baseCost = 0.1
        case .OPENAI_SORA_2_PRO:
            let isHighRes = dimensions == "1792x1024" || dimensions == "1024x1792"
            baseCost = isHighRes ? 0.50 : 0.30
        case .STABILITY_ULTRA:
            baseCost = 8.0
        case .STABILITY_CORE:
            baseCost = 3.0
        case .STABILITY_SDXL:
            baseCost = 0.2
        case .STABILITY_SD3:
            baseCost = 6.5
        case .STABILITY_SD3_TURBO:
            baseCost = 4.0
        case .STABILITY_SD35_LARGE:
            baseCost = 6.5
        case .STABILITY_SD35_LARGE_TURBO:
            baseCost = 4.0
        case .STABILITY_SD35_MEDIUM:
            baseCost = 3.5
        case .STABILITY_SD35_FLASH:
            baseCost = 2.5
        case .STABILITY_CREATIVE_UPSCALE:
            baseCost = 25.0
        case .STABILITY_CONSERVATIVE_UPSCALE:
            baseCost = 25.0
        case .STABILITY_ERASE:
            baseCost = 3.0
        case .STABILITY_INPAINT:
            baseCost = 3.0
        case .STABILITY_OUTPAINT:
            baseCost = 4.0
        case .STABILITY_SEARCH_AND_REPLACE:
            baseCost = 4.0
        case .STABILITY_REMOVE_BACKGROUND:
            baseCost = 2.0
        case .STABILITY_IMAGE_TO_VIDEO:
            baseCost = 20.0
        case .GOOGLE_GEMINI_FLASH_IMAGE, .GOOGLE_GEMINI_FLASH_IMAGE_EDIT:
            let tokensPerImage: Double = 1290
            baseCost = (tokensPerImage / 1_000_000) * 30
        case .GOOGLE_GEMINI_PRO_IMAGE, .GOOGLE_GEMINI_PRO_IMAGE_EDIT:
            let tokensPerImage: Double = quality == .HD ? 2000 : 1210
            baseCost = (tokensPerImage / 1_000_000) * 30
        case .GOOGLE_IMAGEN_3:
            baseCost = 0.03
        case .GOOGLE_IMAGEN_4_FAST:
            baseCost = 0.02
        case .GOOGLE_IMAGEN_4_STANDARD:
            baseCost = quality == .HD ? 0.08 : 0.04
        case .GOOGLE_IMAGEN_4_ULTRA:
            baseCost = quality == .HD ? 0.12 : 0.06
        case .GOOGLE_VEO_31, .GOOGLE_VEO_3:
            baseCost = 0.40
        case .GOOGLE_VEO_31_FAST, .GOOGLE_VEO_3_FAST:
            baseCost = 0.15
        case .GOOGLE_VEO_2:
            baseCost = 0.35
        case .REPLICATE_FLUX_SCHNELL:
            baseCost = 0.003
        case .REPLICATE_FLUX_DEV:
            baseCost = 0.03
        case .REPLICATE_FLUX_PRO:
            baseCost = 0.055
        case .REPLICATE_SEEDREAM_3, .REPLICATE_SEEDREAM_4, .REPLICATE_SEEDREAM_4_EDIT,
             .REPLICATE_SEEDREAM_4_5, .REPLICATE_SEEDREAM_4_5_EDIT, .REPLICATE_DREAMINA_3_1:
            baseCost = 0.03
        case .REPLICATE_SEEDANCE_1_PRO, .REPLICATE_SEEDANCE_1_PRO_EDIT,
             .REPLICATE_SEEDANCE_1_PRO_FAST, .REPLICATE_SEEDANCE_1_PRO_FAST_EDIT,
             .REPLICATE_SEEDANCE_1_LITE, .REPLICATE_SEEDANCE_1_LITE_EDIT:
            baseCost = 0.0
        case .FAL_FLUX_SCHNELL:
            baseCost = 0.003
        case .FAL_FLUX_DEV:
            baseCost = 0.025
        case .FAL_FLUX_PRO:
            baseCost = 0.05
        }
        
        return baseCost * Double(numberOfImages)
    }
    
    private static func OpenAIDallE3Cost(quality: EnumArtQuality, dimensions: String) -> Double {
        switch quality {
        case .STANDARD:
            switch dimensions {
            case "1024x1024":
                return 0.04
            case "1792x1024", "1024x1792":
                return 0.08
            default:
                return 0.08
            }
        case .HD:
            switch dimensions {
            case "1024x1024":
                return 0.08
            case "1792x1024", "1024x1792":
                return 0.12
            default:
                return 0.12
            }
        }
    }
    
    static func estimatedVideoCost(
        modelCode: EnumConnectionModelCode,
        durationSeconds: Int,
        numberOfVideos: Int = 1,
        dimensions: String = "1280x720"
    ) -> Double {
        let costPerSecond: Double
        
        switch modelCode {
        case .STABILITY_IMAGE_TO_VIDEO:
            return 20.0 * Double(numberOfVideos)
        case .OPENAI_SORA_2:
            costPerSecond = 0.10
        case .OPENAI_SORA_2_PRO:
            let isHighRes = dimensions == "1792x1024" || dimensions == "1024x1792"
            costPerSecond = isHighRes ? 0.50 : 0.30
        case .GOOGLE_VEO_31, .GOOGLE_VEO_3:
            costPerSecond = 0.40
        case .GOOGLE_VEO_31_FAST, .GOOGLE_VEO_3_FAST:
            costPerSecond = 0.15
        case .GOOGLE_VEO_2:
            costPerSecond = 0.35
        case .REPLICATE_SEEDANCE_1_PRO, .REPLICATE_SEEDANCE_1_PRO_EDIT:
            if dimensions.contains("1080") {
                costPerSecond = 0.15
            } else if dimensions.contains("720") {
                costPerSecond = 0.06
            } else {
                costPerSecond = 0.03
            }
        case .REPLICATE_SEEDANCE_1_PRO_FAST, .REPLICATE_SEEDANCE_1_PRO_FAST_EDIT:
            if dimensions.contains("1080") {
                costPerSecond = 0.06
            } else if dimensions.contains("720") {
                costPerSecond = 0.025
            } else {
                costPerSecond = 0.015
            }
        case .REPLICATE_SEEDANCE_1_LITE, .REPLICATE_SEEDANCE_1_LITE_EDIT:
            if dimensions.contains("1080") {
                costPerSecond = 0.072
            } else if dimensions.contains("720") {
                costPerSecond = 0.036
            } else {
                costPerSecond = 0.018
            }
            
        default:
            costPerSecond = 0.0
        }
        
        return costPerSecond * Double(durationSeconds) * Double(numberOfVideos)
    }
    
    static func formatCost(_ cost: Double, isCredits: Bool = false) -> String {
        if cost == 0 {
            return "Free"
        } else if isCredits {
            if cost == floor(cost) {
                return String(format: "%.0f credits", cost)
            } else {
                return String(format: "%.1f credits", cost)
            }
        } else if cost < 0.01 {
            return String(format: "$%.4f", cost)
        } else {
            return String(format: "$%.2f", cost)
        }
    }
    
    static func isCreditModel(_ modelCode: EnumConnectionModelCode) -> Bool {
        switch modelCode {
        case .STABILITY_ULTRA, .STABILITY_CORE, .STABILITY_SDXL,
             .STABILITY_SD3, .STABILITY_SD3_TURBO,
             .STABILITY_SD35_LARGE, .STABILITY_SD35_LARGE_TURBO,
             .STABILITY_SD35_MEDIUM, .STABILITY_SD35_FLASH,
             .STABILITY_CREATIVE_UPSCALE, .STABILITY_CONSERVATIVE_UPSCALE,
             .STABILITY_ERASE, .STABILITY_INPAINT, .STABILITY_OUTPAINT,
             .STABILITY_SEARCH_AND_REPLACE, .STABILITY_REMOVE_BACKGROUND,
             .STABILITY_IMAGE_TO_VIDEO:
            return true
        default:
            return false
        }
    }
}

struct EstimatedCostView: View {
    let cost: Double
    var modelCode: EnumConnectionModelCode?
    
    var body: some View {
        let isCredits = modelCode.map { CostEstimator.isCreditModel($0) } ?? false
        HStack {
            Text("Estimated cost:")
                .foregroundColor(.secondary)
            Spacer()
            Text(CostEstimator.formatCost(cost, isCredits: isCredits))
                .fontWeight(.medium)
                .foregroundColor(cost == 0 ? .green : .primary)
        }
    }
}

