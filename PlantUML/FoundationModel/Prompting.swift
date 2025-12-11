//
//  Prompting.swift
//  PlantUMLApp
//
//  Created by bsorrentino on 06/11/25.
//
import Playgrounds
import AnyLanguageModel

@Generable
struct Output {

    @Guide(description: "affermative or negative response")
    var answer: String
}


#Playground {
    

    if let apiKey = readConfigString(forInfoDictionaryKey: "OPENAI_API_KEY"), !apiKey.isEmpty {
        
        let model = OpenAILanguageModel(
            apiKey: apiKey,
            model: "gpt-4o-mini"
        )
        
        let session = LanguageModelSession( model: model )
        
        let response = try await session.respond( to: "do you know plantuml script language?", generating: Output.self)
        
        let answer = response.content.answer
        
    }
}

