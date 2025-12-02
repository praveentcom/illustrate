import Foundation

struct HuggingFaceModels {
    
    static func createModels() -> [ConnectionModel] {
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

