//
//  File.swift
//
//
//  Created by bsorrentino on 12/03/24.
//

import Foundation
import OSLog
import AnyLanguageModel
import LangGraph

@inline(__always) func _EX( _ msg: String ) -> CompiledGraphError {
    CompiledGraphError.executionError(msg)
}

func loadFileFromBundle( fileName: String, withExtension ext: String ) throws -> String {
    guard let filepath = Bundle.module.path(forResource: fileName, ofType: ext) else {
        throw _EX("prompt file \(fileName).\(ext) not found!")
    }
    
    return try String(contentsOfFile: filepath, encoding: .utf8)
}

func loadPromptFromBundle( fileName: String ) throws -> String {
    guard let filepath = Bundle.module.path(forResource: fileName, ofType: "txt") else {
        throw _EX("prompt file \(fileName) not found!")
    }
    
    return try String(contentsOfFile: filepath, encoding: .utf8)
}


public enum DiagramImageValue {
    case data( Data )
    case url( String )
}

struct AgentExecutorState : AgentState {
    
    var data: [String : Any]
    
    init() {
        data = [:]
    }
    
    init(_ initState: [String : Any]) {
        data = initState
    }
    
    var diagramImageUrlOrData:DiagramImageValue? {
        data["diagram_image_url_or_data"] as? DiagramImageValue
    }
    
    var diagramCode:String? {
        data["diagram_code"] as? String
    }
    
    var diagram: DiagramGuide.Description? {
        data["diagram"] as? DiagramGuide.Description
    }
}


func diagramDescriptionOutputParse( _ content: String ) throws -> DiagramGuide.Description {
    let decoder = JSONDecoder()
    if let data = content.data(using: .utf8) {
        
        let desc = try decoder.decode(DiagramGuide.Description.self, from: data )
        
        // error check
        if let error = desc.error, !error.isEmpty {
            throw _EX(error)
        }
        
        return desc
    }
    else {
        throw _EX( "error converting data to DiagramDescription!")
    }
    
//    let regex = #/```(json\n)?({)(?<code>.*)(}\n(```)?)/#.dotMatchesNewlines()
//    
//    if let match = try regex.firstMatch(in: content) {
//        
//        
//        let decoder = JSONDecoder()
//        
//        let code = "{\(match.code)}"
//        
//        if let data = code.data(using: .utf8) {
//            
//            return try decoder.decode(DiagramDescription.self, from: data )
//        }
//        else {
//            throw _EX( "error converting data!")
//        }
//    }
//    else {
//        throw _EX( "content doesn't match schema!")
//    }
    
    
}

func describeDiagramImage<T:AgentExecutorDelegate>( state: AgentExecutorState,
                                                    session: LanguageModelSession,
                                                    delegate:T ) async throws -> PartialAgentState {
    
    guard let imageUrlValue = state.diagramImageUrlOrData else {
        throw _EX("diagramImageUrlOrData not initialized!")
    }
    
    await delegate.progress("starting analyze\ndiagram 👀")

    let schema = try loadFileFromBundle(fileName: "describe_diagram_schema", withExtension: "json")
    let promptTemplate = try loadPromptFromBundle(fileName: "describe_diagram_prompt")

    let prompt = promptTemplate.replacingOccurrences(of: "{DESCRIBE_DIAGRAM_SCHEMA}", with: schema)
    
    let image = switch( imageUrlValue ) {
        case .url( let url):
            if let urlObject = URL(string: url) {
                Transcript.ImageSegment(id: "Diagram01", source: .url( urlObject ) )
            }
            else {
                throw _EX("invalid url: \(url)")

            }
        case .data(let data):
            Transcript.ImageSegment(id: "Diagram01", source: .data(data, mimeType: "image/png"))

        }
        
    let response = try await session.respond(
        to: prompt,
        image: image
    )
    
    await delegate.progress( "diagram processed ✅")

    let content = response.content
    
    // print(content)
    let diagram = try diagramDescriptionOutputParse( content )
        
    await delegate.progress( "diagram type\n '\(diagram.type)'")
        
    return [ "diagram": diagram ]
}


func translateSequenceDiagramDescriptionToPlantUML<T:AgentExecutorDelegate>( state: AgentExecutorState,
                                                    session: LanguageModelSession,
                                                    delegate:T ) async throws -> PartialAgentState {
    
    guard let diagram = state.diagram else {
        throw _EX("diagram not initialized!")
    }
    
    await delegate.progress("translating diagram to\nSequence Diagram")

    var prompt = try loadPromptFromBundle(fileName: "sequence_diagram_prompt")
    
//    let description:String = switch(diagram.description) {
//                case .string(let string):
//                    string
//                case .array(let array ):
//                    array.joined(separator: "\n")
//                }
    let description:String = diagram.description.joined(separator: "\n")
    
    prompt = prompt
        .replacingOccurrences(of: "{diagram_title}", with: diagram.title)
        .replacingOccurrences(of: "{diagram_description}", with: description)
    
    
    let response = try await session.respond( to: prompt, generating: PlantUMLResult.self )
    
    let result =  response.content
    
    return [ "diagram_code": result.script ]

}

func translateDiagramDescriptionToPlantUML<T:AgentExecutorDelegate>( forDiagramType type: String,
                                                                     state: AgentExecutorState,
                                                                     session: LanguageModelSession,
                                                                     delegate:T ) async throws -> PartialAgentState {
    guard let diagram = state.diagram else {
        throw _EX("diagram not initialized!")
    }
    
    await delegate.progress("translating diagram to\n\(diagram.type.capitalized) Diagram")
    
    var prompt = try loadPromptFromBundle(fileName: "\(type)_diagram_prompt")
    
    let encoder = JSONEncoder()
    
    let data = try encoder.encode(diagram)
    
    guard let content = String(data: data, encoding: .utf8) else {
        throw _EX("diagram encoding error!")
    }
    
    prompt = prompt
            .replacingOccurrences(of: "{diagram_description}", with: content)
   
    let response = try await session.respond( to: prompt, generating: PlantUMLResult.self )

    let result =  response.content
    
    return [ "diagram_code": result.script ]
    
}


func routeDiagramTranslation( state: AgentExecutorState ) async throws -> String {
    
    guard let diagram = state.diagram else {
        throw CompiledGraphError.executionError("diagram is nil!")
    }
    switch diagram.type {
    case "sequence":
        return "sequence"
    case "usecase":
        return "usecase"
    default:
        return "generic"
    }
}

@MainActor /* @objc */ public protocol AgentExecutorDelegate {
    
    /* @objc optional */ func progress(_ message: String) -> Void
}

public func runTranslateDrawingToPlantUML<T:AgentExecutorDelegate>( visionModel: any LanguageModel,
                                                                    promptModel: any LanguageModel,
                                                                    imageValue: DiagramImageValue,
                                                                    delegate:T ) async throws -> String? {
    
    let workflow = StateGraph { AgentExecutorState($0) }
    
    let visionSession = LanguageModelSession( model: visionModel )
    let promptSession = LanguageModelSession( model: promptModel )

    try workflow.addNode("agent_describer", action: { state in
        try await describeDiagramImage(state: state,
                                       session: visionSession,
                                       delegate: delegate)
    })
    try workflow.addNode("agent_sequence_plantuml", action: { state in
        try await translateSequenceDiagramDescriptionToPlantUML( state: state,
                                                                 session: promptSession,
                                                                 delegate:delegate )
    })
    try workflow.addNode("agent_usecase_plantuml", action: { state in
        try await translateDiagramDescriptionToPlantUML( forDiagramType: "usecase",
                                                         state: state,
                                                         session: promptSession,
                                                         delegate:delegate )
    })
    try workflow.addNode("agent_generic_plantuml", action: { state in
         try await translateDiagramDescriptionToPlantUML( forDiagramType: "generic",
                                                          state: state,
                                                          session: promptSession,
                                                          delegate:delegate )
    })
    
    try workflow.addEdge(sourceId: "agent_sequence_plantuml", targetId: END)
    try workflow.addEdge(sourceId: "agent_usecase_plantuml", targetId: END)
    try workflow.addEdge(sourceId: "agent_generic_plantuml", targetId: END)
    
    try workflow.addConditionalEdge(
        sourceId: "agent_describer",
        condition: routeDiagramTranslation,
        edgeMapping: [
            "sequence": "agent_sequence_plantuml",
            "usecase": "agent_usecase_plantuml",
            "generic": "agent_generic_plantuml",
        ]
    )
    try workflow.addEdge( sourceId: START, targetId: "agent_describer")
    
    let app = try workflow.compile()
    
    let inputs:[String : Any] = [
         "diagram_image_url_or_data": imageValue
     ]
    
    let response = try await app.invoke( GraphInput.args(inputs) )
    
    return response.diagramCode
}


public func updatePlantUML( languageModel: any LanguageModel,
                            input: String,
                            withInstruction instruction: String ) async throws -> String? {
    
    let system_prompt = try loadPromptFromBundle(fileName: "update_diagram_prompt")
    
    let session = LanguageModelSession( model: languageModel, instructions: system_prompt )
    
    let result = try await session.respond(to: Prompt {
        "starting from the the current <plantuml> script:"
        "<platuml>"
        input
        "</plantuml>"
        "apply the following <instruction>:"
        "<instruction>"
        instruction
        "</instruction>"
    }, generating: PlantUMLResult.self)
   
    return result.content.script

    
}
