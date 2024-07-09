//
//  File.swift
//
//
//  Created by bsorrentino on 12/03/24.
//

import Foundation
import OSLog
import OpenAI
import LangGraph

@inline(__always) func _EX( _ msg: String ) -> CompiledGraphError {
    CompiledGraphError.executionError(msg)
}

func loadPromptFromBundle( fileName: String ) throws -> String {
    guard let filepath = Bundle.module.path(forResource: fileName, ofType: "txt") else {
        throw _EX("prompt file \(fileName) not found!")
    }
    
    return try String(contentsOfFile: filepath, encoding: .utf8)
}


struct DiagramParticipant : Codable {
    var name: String
    var shape: String
    var description: String
}

struct DiagramRelation: Codable {
    var source: String // source
    var target: String // destination
    var description: String
}
struct DiagramContainer: Codable {
    var name: String // source
    var children: [String] // destination
    var description: String
}

enum DiagramNLPDescription : Codable {
    case string(String)
    case array([String])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([String].self) {
            self = .array(array)
        } else {
            throw _EX("Expected string or array of strings")
        }
    }
}

struct DiagramDescription : Codable {
    var type: String
    var title: String
    var participants: [DiagramParticipant]
    var relations: [DiagramRelation]
    var containers: [DiagramContainer]
    var description: DiagramNLPDescription // NLP description
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
    
    var diagram:DiagramDescription? {
        data["diagram"] as? DiagramDescription
    }
}

func diagramDescriptionOutputParse( _ content: String ) throws -> DiagramDescription {
    
    let regex = #/```(json\n)?({)(?<code>.*)(}\n(```)?)/#.dotMatchesNewlines()
    
    if let match = try regex.firstMatch(in: content) {
        
        
        let decoder = JSONDecoder()
        
        let code = "{\(match.code)}"
        
        if let data = code.data(using: .utf8) {
            
            return try decoder.decode(DiagramDescription.self, from: data )
        }
        else {
            throw _EX( "error converting data!")
        }
    }
    else {
        throw _EX( "content doesn't match schema!")
    }
    
    
}

func describeDiagramImage<T:AgentExecutorDelegate>( state: AgentExecutorState,
                                                    openAI:OpenAI,
                                                    delegate:T ) async throws -> PartialAgentState {
    
    guard let imageUrlValue = state.diagramImageUrlOrData else {
        throw _EX("diagramImageUrlOrData not initialized!")
    }
    
    await delegate.progress("starting analyze\ndiagram 👀")

    let prompt = try loadPromptFromBundle(fileName: "describe_diagram_prompt")
  
    let query = switch( imageUrlValue ) {
        case .url( let url):
            ChatQuery(messages: [
                .user(.init(content: .vision([
                    .chatCompletionContentPartTextParam(.init(text: prompt)),
                    .chatCompletionContentPartImageParam(.init(imageUrl: .init(url: url, detail: .auto)))
                ])))
            ], model: Model.gpt4_o, maxTokens: 2000)
        case .data(let data):
            ChatQuery(messages: [
                .user(.init(content: .vision([
                    .chatCompletionContentPartTextParam(.init(text: prompt)),
                    .chatCompletionContentPartImageParam(.init(imageUrl: .init(url: data, detail: .auto)))
                ])))
            ], model: Model.gpt4_o, maxTokens: 2000)

        }
    
//    let query = ChatQuery(
//        model: .gpt4_vision_preview,
//        messages: [
//            Chat(role: .user, content: [
//                ChatContent(text: prompt),
//                ChatContent(imageUrl: imageUrl )
//            ])
//        ],
//        maxTokens: 2000
//    )
        
    let chatResult = try await openAI.chats(query: query)
    
    await delegate.progress( "diagram processed ✅")

    let result = chatResult.choices[0].message.content
    
    if case .string(let content) = result {
        // print(content)
        let diagram = try diagramDescriptionOutputParse( content )
        
        await delegate.progress( "diagram type\n '\(diagram.type)'")
        
        return [ "diagram": diagram ]
    }
    
    throw _EX("invalid content")
}


func translateSequenceDiagramDescriptionToPlantUML<T:AgentExecutorDelegate>( state: AgentExecutorState,
                                                    openAI:OpenAI,
                                                    delegate:T ) async throws -> PartialAgentState {
    
    guard let diagram = state.diagram else {
        throw _EX("diagram not initialized!")
    }
    
    await delegate.progress("translating diagram to\nSequence Diagram")

    var prompt = try loadPromptFromBundle(fileName: "sequence_diagram_prompt")
    
    let description:String = switch(diagram.description) {
                case .string(let string):
                    string
                case .array(let array ):
                    array.joined(separator: "\n")
                }

    prompt = prompt
        .replacingOccurrences(of: "{diagram_title}", with: diagram.title)
        .replacingOccurrences(of: "{diagram_description}", with: description)
    
    let query = ChatQuery(messages: [
        .user(.init(content: .string(prompt)))
    ], model: Model.gpt3_5Turbo, maxTokens: 2000)
    
//    let query = ChatQuery(
//        model: .gpt3_5Turbo,
//        messages: [
//            Chat(role: .user, content: [
//                ChatContent(text: prompt),
//            ])
//        ],
//        maxTokens: 2000
//    )
    
    let chatResult = try await openAI.chats(query: query)
    
    let result = chatResult.choices[0].message.content
    
    guard case .string(let content) = result else  {
        throw _EX( "invalid result!" )
    }
    
    return [ "diagram_code": content ]

}


func translateDiagramDescriptionToPlantUML<T:AgentExecutorDelegate>( state: AgentExecutorState,
                                                                     openAI:OpenAI,
                                                                     delegate:T ) async throws -> PartialAgentState {

    guard let diagram = state.diagram else {
        throw _EX("diagram not initialized!")
    }
    
    await delegate.progress("translating diagram to\n\(diagram.type.capitalized) Diagram")
    
    var prompt = try loadPromptFromBundle(fileName: "\(diagram.type)_diagram_prompt")
    
    let encoder = JSONEncoder()
    
    let data = try encoder.encode(diagram)
    
    guard let content = String(data: data, encoding: .utf8) else {
        throw _EX("diagram encoding error!")
    }
    
    prompt = prompt
            .replacingOccurrences(of: "{diagram_description}", with: content)
   
    let query = ChatQuery(messages: [
        .user(.init(content: .string(prompt)))
    ], model: Model.gpt3_5Turbo, maxTokens: 2000)

    let chatResult = try await openAI.chats(query: query)
    
    let result = chatResult.choices[0].message.content
    
    guard case .string(let content) = result else {
        throw _EX( "invalid result!" )
    }

    return [ "diagram_code": content ]
    
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

public func runTranslateDrawingToPlantUML<T:AgentExecutorDelegate>( openAI: OpenAI, 
                                                                    imageValue: DiagramImageValue,
                                                                    delegate:T ) async throws -> String? {
    
    let workflow = StateGraph { AgentExecutorState() }
    
    try workflow.addNode("agent_describer", action: { state in
        try await describeDiagramImage(state: state, openAI: openAI, delegate: delegate)
    })
    try workflow.addNode("agent_sequence_plantuml", action: { state in
        try await translateSequenceDiagramDescriptionToPlantUML( state: state, openAI:openAI, delegate:delegate )
    })
    try workflow.addNode("agent_usecase_plantuml", action: { state in
         try await translateDiagramDescriptionToPlantUML( state: state, openAI:openAI, delegate:delegate )
    })
    try workflow.addNode("agent_generic_plantuml", action: { state in
         try await translateDiagramDescriptionToPlantUML( state: state, openAI:openAI, delegate:delegate )
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
    try workflow.setEntryPoint( "agent_describer")
    
    let app = try workflow.compile()
    
    let inputs:[String : Any] = [
         "diagram_image_url_or_data": imageValue
     ]
    
    let response = try await app.invoke( inputs: inputs)
    
    return response.diagramCode
}


public func updatePlantUML( openAI: OpenAI, 
                            withModel model: Model,
                            input: String,
                            withInstruction instruction: String ) async throws -> String? {
    
    let system_prompt = try loadPromptFromBundle(fileName: "update_diagram_prompt")
    
    let query = ChatQuery(messages: [
        .system(.init(content: system_prompt)),
        .assistant(.init( content: input)),
        .user(.init(content: .string(instruction)))
    ], model: model, temperature: 0.0, topP: 1.0)

//    let query = ChatQuery(
//        model: model,
//        messages: [
//            .init(role: .system, content:
//                            """
//                            You are my plantUML assistant.
//                            You must answer exclusively with diagram syntax.
//                            """),
//            .init( role: .assistant, content: input ),
//            .init( role: .user, content: instruction )
//        ],
//        temperature: 0.0,
//        topP: 1.0
//    )

    let chat = try await openAI.chats(query: query)

    let result = chat.choices[0].message.content

    if case .string(let content) = result {
        
        return content
    }
    
    return nil

}
