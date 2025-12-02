import Foundation
import SwiftUI

/// Service class responsible for managing connection models
/// Replaces the global connectionModels array for better architecture
class ConnectionService: ObservableObject {
    static let shared = ConnectionService()

    @Published private var _models: [ConnectionModel] = []

    // MARK: - Initialization

    private init() {
        loadModels()
    }

    // MARK: - Public Interface

    /// Get all connection models
    var allModels: [ConnectionModel] {
        return _models
    }

    /// Get active models only
    var activeModels: [ConnectionModel] {
        return _models.filter { $0.active }
    }

    /// Get models by set type
    func models(for setType: EnumSetType) -> [ConnectionModel] {
        return _models.filter { $0.modelSetType == setType && $0.active }
    }

    /// Get models by connection code
    func models(for connectionCode: EnumConnectionCode) -> [ConnectionModel] {
        return _models.filter { $0.connectionId == connectionCode.connectionId && $0.active }
    }

    /// Get models by connection ID (UUID)
    func models(for connectionId: UUID) -> [ConnectionModel] {
        return _models.filter { $0.connectionId == connectionId && $0.active }
    }

    /// Get model by model ID
    func model(by modelId: String) -> ConnectionModel? {
        return _models.first { $0.modelId.uuidString == modelId }
    }

    /// Get model by enum code
    func model(by code: EnumConnectionModelCode) -> ConnectionModel? {
        return _models.first { $0.modelCode == code }
    }

    /// Check if a model is active
    func isModelActive(_ code: EnumConnectionModelCode) -> Bool {
        return model(by: code)?.active ?? false
    }

    /// Get supported dimensions for a model
    func supportedDimensions(for modelId: String) -> [String] {
        return model(by: modelId)?.modelSupportedParams.dimensions ?? []
    }

    /// Get max prompt length for a model
    func maxPromptLength(for modelId: String) -> Int {
        return model(by: modelId)?.modelSupportedParams.maxPromptLength ?? 256
    }

    /// Check if OpenAI is connected
    func isOpenAIConnected(connectionKeys: [ConnectionKey]) -> Bool {
        return connectionKeys.contains { $0.connectionId == EnumConnectionCode.OPENAI.connectionId }
    }

    // MARK: - Private Methods

    /// Load models from the centralized configuration
    private func loadModels() {
        _models = ConnectionModelFactory.createAllModels()
    }

    /// Refresh models from factory (useful for updates)
    func refreshModels() {
        loadModels()
    }
}

// MARK: - Factory Pattern for Model Creation

/// Factory responsible for creating connection models
/// Separates model configuration from service logic
private struct ConnectionModelFactory {

    static func createAllModels() -> [ConnectionModel] {
        return [
            createOpenAIModels(),
            createStabilityModels(),
            createGoogleCloudModels(),
            createReplicateModels(),
            createFALModels(),
            createHuggingFaceModels()
        ].flatMap { $0 }
    }

    // MARK: - OpenAI Models

    private static func createOpenAIModels() -> [ConnectionModel] {
        return [
            ConnectionModel(
                connectionId: EnumConnectionCode.OPENAI.connectionId,
                modelId: EnumConnectionModelCode.OPENAI_DALLE3.modelId,
                modelCode: EnumConnectionModelCode.OPENAI_DALLE3,
                modelSetType: EnumSetType.GENERATE,
                modelName: "DALL·E 3",
                modelDescription: "DALL·E 3 represents a leap forward in our ability to generate images that exactly adhere to the text you provide.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: false,
                    maxPromptLength: 4000,
                    dimensions: ["1024x1024", "1792x1024", "1024x1792"],
                    quality: true,
                    variant: true,
                    style: true,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-08-20"),
                modelGenerateBaseURL: "https://api.openai.com/v1/images/generations",
                modelAPIDocumentationURL: "https://platform.openai.com/docs/api-reference/images/create",
                active: true
            )
        ]
    }

    // MARK: - Stability Models

    private static func createStabilityModels() -> [ConnectionModel] {
        return [
            ConnectionModel(
                connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
                modelId: EnumConnectionModelCode.STABILITY_ULTRA.modelId,
                modelCode: EnumConnectionModelCode.STABILITY_ULTRA,
                modelSetType: EnumSetType.GENERATE,
                modelName: "Stable Ultra",
                modelDescription: "Stable Image Ultra creates the highest quality images with unprecedented prompt understanding.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 1024,
                    dimensions: ["1024x1024", "576x1024", "1024x576", "1344x576", "576x1344", "1536x1024", "1024x1536", "1280x1024", "1024x1280"],
                    quality: false,
                    variant: true,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-07-26"),
                modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/generate/ultra",
                modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Generate/paths/~1v2beta~1stable-image~1generate~1ultra/post",
                active: true
            ),
            ConnectionModel(
                connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
                modelId: EnumConnectionModelCode.STABILITY_CORE.modelId,
                modelCode: EnumConnectionModelCode.STABILITY_CORE,
                modelSetType: EnumSetType.GENERATE,
                modelName: "Stable Core",
                modelDescription: "Stable Image Core represents the best quality achievable at high speed.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 1024,
                    dimensions: ["1024x1024", "576x1024", "1024x576", "1344x576", "576x1344", "1536x1024", "1024x1536", "1280x1024", "1024x1280"],
                    quality: false,
                    variant: true,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-07-26"),
                modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/generate/core",
                modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Generate/paths/~1v2beta~1stable-image~1generate~1core/post",
                active: true
            ),
            ConnectionModel(
                connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
                modelId: EnumConnectionModelCode.STABILITY_SDXL.modelId,
                modelCode: EnumConnectionModelCode.STABILITY_SDXL,
                modelSetType: EnumSetType.GENERATE,
                modelName: "Stable XL 1.0 (SDXL)",
                modelDescription: "Stable Diffusion XL (SDXL) is a powerful text-to-image generation model.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 1024,
                    dimensions: ["1024x1024", "1152x896", "896x1152", "1216x832", "1344x768", "768x1344", "1536x640", "640x1536"],
                    quality: false,
                    variant: true,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-07-26"),
                modelGenerateBaseURL: "https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image",
                modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/SDXL-and-SD1.6",
                active: true
            ),
            ConnectionModel(
                connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
                modelId: EnumConnectionModelCode.STABILITY_SD3.modelId,
                modelCode: EnumConnectionModelCode.STABILITY_SD3,
                modelSetType: EnumSetType.GENERATE,
                modelName: "Stable 3.0 Large (Deprecated)",
                modelDescription: "Generate images using Stable Diffusion 3 Large (SD3). This model is deprecated - please use SD 3.5 models instead.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 1024,
                    dimensions: ["1024x1024", "576x1024", "1024x576", "1344x576", "576x1344", "1536x1024", "1024x1536", "1280x1024", "1024x1280"],
                    quality: false,
                    variant: true,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-07-26"),
                modelDeprecationDate: getDateFromString("2024-10-01"),
                modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/generate/sd3",
                modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Generate/paths/~1v2beta~1stable-image~1generate~1sd3/post",
                active: false
            ),
            ConnectionModel(
                connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
                modelId: EnumConnectionModelCode.STABILITY_SD3_TURBO.modelId,
                modelCode: EnumConnectionModelCode.STABILITY_SD3_TURBO,
                modelSetType: EnumSetType.GENERATE,
                modelName: "Stable 3.0 Turbo (Deprecated)",
                modelDescription: "Generate images using Stable Diffusion 3 Large Turbo (SD3 Turbo). This model is deprecated - please use SD 3.5 Large Turbo instead.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 1024,
                    dimensions: ["1024x1024", "576x1024", "1024x576", "1344x576", "576x1344", "1536x1024", "1024x1536", "1280x1024", "1024x1280"],
                    quality: false,
                    variant: true,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-07-26"),
                modelDeprecationDate: getDateFromString("2024-10-01"),
                modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/generate/sd3",
                modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Generate/paths/~1v2beta~1stable-image~1generate~1sd3/post",
                active: false
            ),
            ConnectionModel(
                connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
                modelId: EnumConnectionModelCode.STABILITY_SD35_LARGE.modelId,
                modelCode: EnumConnectionModelCode.STABILITY_SD35_LARGE,
                modelSetType: EnumSetType.GENERATE,
                modelName: "Stable 3.5 Large",
                modelDescription: "Generate images using Stable Diffusion 3.5 Large (SD3.5), our most capable model for high-quality image generation.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 1024,
                    dimensions: ["1024x1024", "576x1024", "1024x576", "1344x576", "576x1344", "1536x1024", "1024x1536", "1280x1024", "1024x1280"],
                    quality: false,
                    variant: true,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2024-10-01"),
                modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/generate/sd3",
                modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Generate/paths/~1v2beta~1stable-image~1generate~1sd3/post",
                active: true
            ),
            ConnectionModel(
                connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
                modelId: EnumConnectionModelCode.STABILITY_SD35_LARGE_TURBO.modelId,
                modelCode: EnumConnectionModelCode.STABILITY_SD35_LARGE_TURBO,
                modelSetType: EnumSetType.GENERATE,
                modelName: "Stable 3.5 Large Turbo",
                modelDescription: "Generate images using Stable Diffusion 3.5 Large Turbo (SD3.5 Turbo), a faster version of our most capable model.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 1024,
                    dimensions: ["1024x1024", "576x1024", "1024x576", "1344x576", "576x1344", "1536x1024", "1024x1536", "1280x1024", "1024x1280"],
                    quality: false,
                    variant: true,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2024-10-01"),
                modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/generate/sd3",
                modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Generate/paths/~1v2beta~1stable-image~1generate~1sd3/post",
                active: true
            ),
            ConnectionModel(
                connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
                modelId: EnumConnectionModelCode.STABILITY_SD35_MEDIUM.modelId,
                modelCode: EnumConnectionModelCode.STABILITY_SD35_MEDIUM,
                modelSetType: EnumSetType.GENERATE,
                modelName: "Stable 3.5 Medium",
                modelDescription: "Generate images using Stable Diffusion 3.5 Medium (SD3.5), balancing quality and speed for efficient generation.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 1024,
                    dimensions: ["1024x1024", "576x1024", "1024x576", "1344x576", "576x1344", "1536x1024", "1024x1536", "1280x1024", "1024x1280"],
                    quality: false,
                    variant: true,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2024-10-01"),
                modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/generate/sd3",
                modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Generate/paths/~1v2beta~1stable-image~1generate~1sd3/post",
                active: true
            ),
            ConnectionModel(
                connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
                modelId: EnumConnectionModelCode.STABILITY_SD35_FLASH.modelId,
                modelCode: EnumConnectionModelCode.STABILITY_SD35_FLASH,
                modelSetType: EnumSetType.GENERATE,
                modelName: "Stable 3.5 Flash",
                modelDescription: "Generate images using Stable Diffusion 3.5 Flash (SD3.5), our fastest model for quick generations.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 1024,
                    dimensions: ["1024x1024", "576x1024", "1024x576", "1344x576", "576x1344", "1536x1024", "1024x1536", "1280x1024", "1024x1280"],
                    quality: false,
                    variant: true,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2024-10-01"),
                modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/generate/sd3",
                modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Generate/paths/~1v2beta~1stable-image~1generate~1sd3/post",
                active: true
            ),
            ConnectionModel(
                connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
                modelId: EnumConnectionModelCode.STABILITY_CREATIVE_UPSCALE.modelId,
                modelCode: EnumConnectionModelCode.STABILITY_CREATIVE_UPSCALE,
                modelSetType: EnumSetType.EDIT_UPSCALE,
                modelName: "Stable Creative Upscale",
                modelDescription: "Takes images between 64x64 and 1 megapixel and upscales them all the way to 4K resolution.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 1024,
                    dimensions: ["1024x1024", "576x1024", "1024x576", "768x1024", "1024x768"],
                    quality: false,
                    variant: false,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-07-26"),
                modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/upscale/creative",
                modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Upscale/paths/~1v2beta~1stable-image~1upscale~1creative/post",
                active: true
            ),
            ConnectionModel(
                connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
                modelId: EnumConnectionModelCode.STABILITY_CONSERVATIVE_UPSCALE.modelId,
                modelCode: EnumConnectionModelCode.STABILITY_CONSERVATIVE_UPSCALE,
                modelSetType: EnumSetType.EDIT_UPSCALE,
                modelName: "Stable Conservative Upscale",
                modelDescription: "Takes images between 64x64 and 1 megapixel and upscales them all the way to 4K resolution.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 1024,
                    dimensions: ["1024x1024", "576x1024", "1024x576", "768x1024", "1024x768"],
                    quality: false,
                    variant: false,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-07-26"),
                modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/upscale/conservative",
                modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Upscale/paths/~1v2beta~1stable-image~1upscale~1conservative/post",
                active: true
            ),
            ConnectionModel(
                connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
                modelId: EnumConnectionModelCode.STABILITY_ERASE.modelId,
                modelCode: EnumConnectionModelCode.STABILITY_ERASE,
                modelSetType: EnumSetType.EDIT_MASK_ERASE,
                modelName: "Stable Erase",
                modelDescription: "The Erase service removes unwanted objects, such as blemishes on portraits or items on desks, using image masks.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 1024,
                    dimensions: ["1024x1024", "576x1024", "1024x576", "768x1024", "1024x768"],
                    quality: false,
                    variant: false,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-07-26"),
                modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/edit/erase",
                modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Edit/paths/~1v2beta~1stable-image~1edit~1erase/post",
                active: true
            ),
            ConnectionModel(
                connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
                modelId: EnumConnectionModelCode.STABILITY_INPAINT.modelId,
                modelCode: EnumConnectionModelCode.STABILITY_INPAINT,
                modelSetType: EnumSetType.EDIT_MASK,
                modelName: "Stable Inpaint",
                modelDescription: "Intelligently modify images by filling in or replacing specified areas with new content based on the content of a mask image.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 1024,
                    dimensions: ["1024x1024", "576x1024", "1024x576", "768x1024", "1024x768"],
                    quality: false,
                    variant: false,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-07-26"),
                modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/edit/inpaint",
                modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Edit/paths/~1v2beta~1stable-image~1edit~1inpaint/post",
                active: true
            ),
            ConnectionModel(
                connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
                modelId: EnumConnectionModelCode.STABILITY_OUTPAINT.modelId,
                modelCode: EnumConnectionModelCode.STABILITY_OUTPAINT,
                modelSetType: EnumSetType.EDIT_EXPAND,
                modelName: "Stable Outpaint",
                modelDescription: "The Outpaint service inserts additional content in an image to fill in the space in any direction.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 1024,
                    dimensions: ["1024x1024", "576x1024", "1024x576", "768x1024", "1024x768"],
                    quality: false,
                    variant: false,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-07-26"),
                modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/edit/outpaint",
                modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Edit/paths/~1v2beta~1stable-image~1edit~1outpaint/post",
                active: true
            ),
            ConnectionModel(
                connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
                modelId: EnumConnectionModelCode.STABILITY_SEARCH_AND_REPLACE.modelId,
                modelCode: EnumConnectionModelCode.STABILITY_SEARCH_AND_REPLACE,
                modelSetType: EnumSetType.EDIT_REPLACE,
                modelName: "Stable Search and Replace",
                modelDescription: "The Search and Replace service is a specific version of inpainting that does not require a mask.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 1024,
                    dimensions: ["1024x1024", "576x1024", "1024x576", "768x1024", "1024x768"],
                    quality: false,
                    variant: false,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-07-26"),
                modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/edit/search-and-replace",
                modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Edit/paths/~1v2beta~1stable-image~1edit~1search-and-replace/post",
                active: true
            ),
            ConnectionModel(
                connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
                modelId: EnumConnectionModelCode.STABILITY_REMOVE_BACKGROUND.modelId,
                modelCode: EnumConnectionModelCode.STABILITY_REMOVE_BACKGROUND,
                modelSetType: EnumSetType.REMOVE_BACKGROUND,
                modelName: "Stable Remove Background",
                modelDescription: "The Remove Background service accurately segments the foreground from an image and implements and removes the background.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 1024,
                    dimensions: ["1024x1024", "576x1024", "1024x576", "768x1024", "1024x768"],
                    quality: false,
                    variant: false,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-07-26"),
                modelGenerateBaseURL: "https://api.stability.ai/v2beta/stable-image/edit/remove-background",
                modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Edit/paths/~1v2beta~1stable-image~1edit~1remove-background/post",
                active: true
            ),
            ConnectionModel(
                connectionId: EnumConnectionCode.STABILITY_AI.connectionId,
                modelId: EnumConnectionModelCode.STABILITY_IMAGE_TO_VIDEO.modelId,
                modelCode: EnumConnectionModelCode.STABILITY_IMAGE_TO_VIDEO,
                modelSetType: EnumSetType.VIDEO_IMAGE,
                modelName: "Stable Image to Video",
                modelDescription: "Generate a short video based on an initial image with Stable Video Diffusion, a latent video diffusion model.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 1024,
                    dimensions: ["768x768", "576x1024", "1024x576"],
                    quality: false,
                    variant: false,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-07-26"),
                modelGenerateBaseURL: "https://api.stability.ai/v2beta/image-to-video",
                modelAPIDocumentationURL: "https://platform.stability.ai/docs/api-reference#tag/Image-to-Video",
                active: true
            )
        ]
    }

    // MARK: - Google Cloud Models

    private static func createGoogleCloudModels() -> [ConnectionModel] {
        return [
            ConnectionModel(
                connectionId: EnumConnectionCode.GOOGLE_CLOUD.connectionId,
                modelId: EnumConnectionModelCode.GCLOUD_IMAGEN2.modelId,
                modelCode: EnumConnectionModelCode.GCLOUD_IMAGEN2,
                modelSetType: EnumSetType.GENERATE,
                modelName: "Imagen 2",
                modelDescription: "Text-to-image diffusion technology, delivering photorealistic outputs that are aligned and consistent with the user's prompt.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 256,
                    dimensions: ["1024x1024","576x1024","1024x576","768x1024","1024x768"],
                    quality: false,
                    variant: true,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-07-26"),
                modelGenerateBaseURL: "us-central1-aiplatform.googleapis.com",
                modelAPIDocumentationURL: "https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/image-generation",
                active: true
            )
        ]
    }

    // MARK: - Replicate Models

    private static func createReplicateModels() -> [ConnectionModel] {
        return [
            ConnectionModel(
                connectionId: EnumConnectionCode.REPLICATE.connectionId,
                modelId: EnumConnectionModelCode.REPLICATE_FLUX_SCHNELL.modelId,
                modelCode: EnumConnectionModelCode.REPLICATE_FLUX_SCHNELL,
                modelSetType: EnumSetType.GENERATE,
                modelName: "FLUX.1 [schnell]",
                modelDescription: "The fastest image generation model tailored for local development and personal use.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 256,
                    dimensions: ["1024x1024", "1920x1080", "2560x1080", "1024x1536", "1620x1080", "1280x1024", "1080x1920", "1080x2520"],
                    quality: false,
                    variant: true,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-12-13"),
                modelGenerateBaseURL: "https://api.replicate.com/v1/models/black-forest-labs/flux-schnell/predictions",
                modelStatusBaseURL: "https://api.replicate.com/v1/predictions",
                modelAPIDocumentationURL: "https://replicate.com/black-forest-labs/flux-schnell?input=http",
                active: true
            ),
            ConnectionModel(
                connectionId: EnumConnectionCode.REPLICATE.connectionId,
                modelId: EnumConnectionModelCode.REPLICATE_FLUX_DEV.modelId,
                modelCode: EnumConnectionModelCode.REPLICATE_FLUX_DEV,
                modelSetType: EnumSetType.GENERATE,
                modelName: "FLUX.1 [dev]",
                modelDescription: "A 12 billion parameter rectified flow transformer capable of generating images from text descriptions.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 256,
                    dimensions: ["1024x1024", "1920x1080", "2560x1080", "1024x1536", "1620x1080", "1280x1024", "1080x1920", "1080x2520"],
                    quality: false,
                    variant: true,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-12-13"),
                modelGenerateBaseURL: "https://api.replicate.com/v1/models/black-forest-labs/flux-dev/predictions",
                modelStatusBaseURL: "https://api.replicate.com/v1/predictions",
                modelAPIDocumentationURL: "https://replicate.com/black-forest-labs/flux-dev?input=http",
                active: true
            ),
            ConnectionModel(
                connectionId: EnumConnectionCode.REPLICATE.connectionId,
                modelId: EnumConnectionModelCode.REPLICATE_FLUX_PRO.modelId,
                modelCode: EnumConnectionModelCode.REPLICATE_FLUX_PRO,
                modelSetType: EnumSetType.GENERATE,
                modelName: "FLUX.1 [pro]",
                modelDescription: "State-of-the-art image generation with top of the line prompt following, visual quality, image detail and output diversity.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 256,
                    dimensions: ["1024x1024", "1920x1080", "1024x1536", "1620x1080", "1280x1024", "1080x1920"],
                    quality: false,
                    variant: true,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-07-26"),
                modelGenerateBaseURL: "https://api.replicate.com/v1/models/black-forest-labs/flux-pro/predictions",
                modelStatusBaseURL: "https://api.replicate.com/v1/predictions",
                modelAPIDocumentationURL: "https://replicate.com/black-forest-labs/flux-pro?input=http",
                active: true
            )
        ]
    }

    // MARK: - FAL Models

    private static func createFALModels() -> [ConnectionModel] {
        return [
            ConnectionModel(
                connectionId: EnumConnectionCode.FAL_AI.connectionId,
                modelId: EnumConnectionModelCode.FAL_FLUX_SCHNELL.modelId,
                modelCode: EnumConnectionModelCode.FAL_FLUX_SCHNELL,
                modelSetType: EnumSetType.GENERATE,
                modelName: "FLUX.1 [schnell]",
                modelDescription: "The fastest image generation model tailored for local development and personal use.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 256,
                    dimensions: ["1024x1024", "1920x1080", "1440x1080", "1080x1920", "1080x1440"],
                    quality: false,
                    variant: true,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-12-13"),
                modelGenerateBaseURL: "https://fal.run/fal-ai/flux/schnell",
                modelAPIDocumentationURL: "https://fal.ai/models/fal-ai/flux/schnell",
                active: true
            ),
            ConnectionModel(
                connectionId: EnumConnectionCode.FAL_AI.connectionId,
                modelId: EnumConnectionModelCode.FAL_FLUX_DEV.modelId,
                modelCode: EnumConnectionModelCode.FAL_FLUX_DEV,
                modelSetType: EnumSetType.GENERATE,
                modelName: "FLUX.1 [dev]",
                modelDescription: "A 12 billion parameter rectified flow transformer capable of generating images from text descriptions.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 256,
                    dimensions: ["1024x1024", "1920x1080", "1440x1080", "1080x1920", "1080x1440"],
                    quality: false,
                    variant: true,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-12-13"),
                modelGenerateBaseURL: "https://fal.run/fal-ai/flux/dev",
                modelAPIDocumentationURL: "https://fal.ai/models/fal-ai/flux/dev",
                active: true
            ),
            ConnectionModel(
                connectionId: EnumConnectionCode.FAL_AI.connectionId,
                modelId: EnumConnectionModelCode.FAL_FLUX_PRO.modelId,
                modelCode: EnumConnectionModelCode.FAL_FLUX_PRO,
                modelSetType: EnumSetType.GENERATE,
                modelName: "FLUX.1 [pro]",
                modelDescription: "State-of-the-art image generation with top of the line prompt following, visual quality, image detail and output diversity.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 256,
                    dimensions: ["1024x1024", "1920x1080", "1440x1080", "1080x1920", "1080x1440"],
                    quality: false,
                    variant: true,
                    style: false,
                    count: 6,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-07-26"),
                modelGenerateBaseURL: "https://fal.run/fal-ai/flux-pro",
                modelAPIDocumentationURL: "https://fal.ai/models/fal-ai/flux-pro",
                active: true
            )
        ]
    }

    // MARK: - Hugging Face Models

    private static func createHuggingFaceModels() -> [ConnectionModel] {
        return [
            ConnectionModel(
                connectionId: EnumConnectionCode.HUGGING_FACE.connectionId,
                modelId: EnumConnectionModelCode.HUGGING_FACE_FLUX_SCHNELL.modelId,
                modelCode: EnumConnectionModelCode.HUGGING_FACE_FLUX_SCHNELL,
                modelSetType: EnumSetType.GENERATE,
                modelName: "FLUX.1 [schnell]",
                modelDescription: "The fastest image generation model tailored for local development and personal use.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 256,
                    dimensions: ["1024x1024"],
                    quality: false,
                    variant: true,
                    style: false,
                    count: 1,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-12-13"),
                modelGenerateBaseURL: "https://api-inference.huggingface.co/models/black-forest-labs/FLUX.1-schnell",
                modelStatusBaseURL: "https://api-inference.huggingface.co/models/black-forest-labs/FLUX.1-schnell",
                modelAPIDocumentationURL: "https://huggingface.co/spaces/black-forest-labs/FLUX.1-schnell",
                active: true
            ),
            ConnectionModel(
                connectionId: EnumConnectionCode.HUGGING_FACE.connectionId,
                modelId: EnumConnectionModelCode.HUGGING_FACE_FLUX_DEV.modelId,
                modelCode: EnumConnectionModelCode.HUGGING_FACE_FLUX_DEV,
                modelSetType: EnumSetType.GENERATE,
                modelName: "FLUX.1 [dev]",
                modelDescription: "A 12 billion parameter rectified flow transformer capable of generating images from text descriptions.",
                modelSupportedParams: ConnectionModelSupportParams(
                    prompt: true,
                    negativePrompt: true,
                    maxPromptLength: 256,
                    dimensions: ["1024x1024", "1920x1080", "1440x1080", "1080x1920", "1080x1440"],
                    quality: false,
                    variant: true,
                    style: false,
                    count: 1,
                    autoEnhance: true
                ),
                modelLaunchDate: getDateFromString("2023-12-13"),
                modelGenerateBaseURL: "https://api-inference.huggingface.co/models/black-forest-labs/FLUX.1-dev",
                modelStatusBaseURL: "https://api-inference.huggingface.co/models/black-forest-labs/FLUX.1-dev",
                modelAPIDocumentationURL: "https://huggingface.co/spaces/black-forest-labs/FLUX.1-dev",
                active: true
            )
        ]
    }
}

// MARK: - Environment Key for SwiftUI

struct ConnectionServiceKey: EnvironmentKey {
    static let defaultValue = ConnectionService.shared
}

extension EnvironmentValues {
    var connectionService: ConnectionService {
        get { self[ConnectionServiceKey.self] }
        set { self[ConnectionServiceKey.self] = newValue }
    }
}
