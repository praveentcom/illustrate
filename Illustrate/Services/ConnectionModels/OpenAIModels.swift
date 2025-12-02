import Foundation

struct OpenAIModels {
    
    static func createModels() -> [ConnectionModel] {
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
}

