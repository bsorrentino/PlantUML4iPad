//
//  Prompting.swift
//  PlantUMLApp
//
//  Created by bsorrentino on 06/11/25.
//
import Playgrounds
import FoundationModels
//import OpenFoundationModels

@Generable
struct StructturedOutput {
    
}


#Playground {
    let session = LanguageModelSession()
    
    let sl = SystemLanguageModel.default.supportedLanguages
    
    let response = try await session.respond(to: "do you know plantuml script language?")

}

