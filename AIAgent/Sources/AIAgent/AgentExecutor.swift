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


struct DiagramParticipant : Codable, JSONSchemaConvertible {
    static var example: DiagramParticipant {
        .init(name: "Event Stream", shape: "cylinder", description: "Source of event data")
    }
    
    var name: String
    var shape: String
    var description: String
    
}

struct DiagramRelation: Codable, JSONSchemaConvertible {
    static var example: DiagramRelation {
        .init(source: "Event Stream", target: "Preprocessing", description: "Feeds into")
    }
    
    var source: String // source
    var target: String // destination
    var description: String
}
struct DiagramContainer: Codable, JSONSchemaConvertible {
    static var example: DiagramContainer {
        .init(name: "Stream Processor",
              children: ["Preprocessing", "LLM Application", "Postprocessing"],
              description: "Processes the event stream")
    }
    
    var name: String // source
    var children: [String] // destination
    var description: String
}

struct PlantUMLResult: Codable, JSONSchemaConvertible {
    static var example: PlantUMLResult {
        .init(script: """
              @startuml Simple Flow Diagram
              rectangle "Start process A" as ProcessA <<Start process A>>
              rectangle "Process B" as ProcessB <<Process B>>
              rectangle "Process C" as ProcessC <<Process C>>
              rectangle "End process" as EndProcess <<End process>>
              ProcessA -> ProcessB : transition from A to B
              ProcessB -> ProcessC : transition from B to C
              ProcessC -> EndProcess : transition from C to Stop
              legend
              Start at process A.
              Move from process A to process B.
              Move from process B to process C.
              End process at Stop.
              end legend
              """)
    }
    
    var script: String
}
//enum DiagramNLPDescription : Codable {
//
//    case string(String)
//    case array([String])
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.singleValueContainer()
//        if let string = try? container.decode(String.self) {
//            self = .string(string)
//        } else if let array = try? container.decode([String].self) {
//            self = .array(array)
//        } else {
//            throw _EX("Expected string or array of strings")
//        }
//    }
//}

/**
 {
     "type": "process",
     "title": "LLM Application Data Flow",
     "participants": [
         { "name": "Event Stream", "shape": "cylinder", "description":  },
         { "name": "Preprocessing", "shape": "rectangle", "description": "Initial processing of events" },
         { "name": "LLM Application", "shape": "rectangle", "description": "Main application processing events" },
         { "name": "Postprocessing", "shape": "rectangle", "description": "Processing after main application" },
         { "name": "Output", "shape": "cylinder", "description": "Final output of the data flow" },
         { "name": "Observability", "shape": "rectangle", "description": "Metrics and logs monitoring" },
         { "name": "LLM Service", "shape": "rectangle", "description": "External service for LLM (e.g., OpenAI)" },
         { "name": "LLM Tracing", "shape": "rectangle", "description": "Tracing service for LLM (e.g., LangSmith)" }
     ],
     "relations": [
         { "source": "Event Stream", "target": "Preprocessing", "description": "Feeds into" },
         { "source": "Preprocessing", "target": "LLM Application", "description": "Feeds into" },
         { "source": "LLM Application", "target": "Postprocessing", "description": "Feeds into" },
         { "source": "Postprocessing", "target": "Output", "description": "Feeds into" },
         { "source": "LLM Application", "target": "Observability", "description": "Sends data to" },
         { "source": "LLM Application", "target": "LLM Service", "description": "Interacts with" },
         { "source": "LLM Application", "target": "LLM Tracing", "description": "Interacts with" }
     ],
     "containers": [
         { "name": "Stream Processor", "children": ["Preprocessing", "LLM Application", "Postprocessing"], "description": "Processes the event stream" }
     ],
     "description": [
         "The Event Stream is the starting point, which feeds into Preprocessing.",
         "Preprocessing is part of the Stream Processor and prepares data for the LLM Application.",
         "The LLM Application processes the data and may interact with external services like LLM Service and LLM Tracing.",
         "After processing, the data is sent to Postprocessing, which is also part of the Stream Processor.",
         "The Postprocessing stage prepares the final Output.",
         "Throughout the process, the LLM Application sends data to Observability for monitoring purposes."
     ]
 }
 */
struct DiagramDescription : Codable, JSONSchemaConvertible {
    static var example: DiagramDescription {
        .init(type: "process",
              title: "LLM Application Data Flow",
              participants: [
                DiagramParticipant(name: "Event Stream", shape: "cylinder", description: "Source of event data" ),
                DiagramParticipant(name: "Preprocessing", shape: "rectangle", description: "Initial processing of events" ),
                DiagramParticipant( name: "LLM Application", shape: "rectangle", description: "Main application processing events" ),
                DiagramParticipant( name: "Postprocessing", shape: "rectangle", description: "Processing after main application" ),

              ],
              relations: [
                DiagramRelation( source: "Event Stream", target: "Preprocessing", description: "Feeds into" ),
                DiagramRelation( source: "Preprocessing", target: "LLM Application", description: "Feeds into" ),

              ],
              containers: [
                DiagramContainer(name: "Stream Processor",
                                 children: ["Preprocessing", "LLM Application", "Postprocessing"],
                                 description: "Processes the event stream")
              ],
              description: [
                "The Event Stream is the starting point, which feeds into Preprocessing.",
                "Preprocessing is part of the Stream Processor and prepares data for the LLM Application.",
                "The LLM Application processes the data and may interact with external services like LLM Service and LLM Tracing.",
              ],
              error: "the image doesn't contains a valid diagram"
        )
    }
    
    
    var type: String
    var title: String
    var participants: [DiagramParticipant]
    var relations: [DiagramRelation]
    var containers: [DiagramContainer]
    //var description: DiagramNLPDescription // NLP description
    var description: [String]
    var error: String?
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

func plantumlOutputParse( _ content: String ) throws -> PlantUMLResult {
    let decoder = JSONDecoder()
    if let data = content.data(using: .utf8) {
        
       return try decoder.decode(PlantUMLResult.self, from: data )
        
    }
    else {
        throw _EX( "error converting data to PlantUMLResult!")
    }
}

func diagramDescriptionOutputParse( _ content: String ) throws -> DiagramDescription {
    let decoder = JSONDecoder()
    if let data = content.data(using: .utf8) {
        
        let desc = try decoder.decode(DiagramDescription.self, from: data )
        
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
                                                    openAI:OpenAI,
                                                    visionModel: String,
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
            ],
                      model: visionModel,
                      maxCompletionTokens: 2000,
                      responseFormat: .derivedJsonSchema(name: "diagram description",
                                                         type: DiagramDescription.self))
        case .data(let data):
            ChatQuery(messages: [
                .user(.init(content: .vision([
                    .chatCompletionContentPartTextParam(.init(text: prompt)),
                    .chatCompletionContentPartImageParam(.init(imageUrl: .init(url: data, detail: .auto)))
                ])))
            ],        model: visionModel,
                      maxCompletionTokens: 2000,
                      responseFormat: .derivedJsonSchema(name: "diagram description",
                                                         type: DiagramDescription.self))


        }
        
    let chatResult = try await openAI.chats(query: query)
    
    await delegate.progress( "diagram processed ✅")

    if let content = chatResult.choices[0].message.content {
    
        // print(content)
        let diagram = try diagramDescriptionOutputParse( content )
        
        await delegate.progress( "diagram type\n '\(diagram.type)'")
        
        return [ "diagram": diagram ]
    }
    
    throw _EX("invalid content")
}


func translateSequenceDiagramDescriptionToPlantUML<T:AgentExecutorDelegate>( state: AgentExecutorState,
                                                    openAI:OpenAI,
                                                    promptModel: String,
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
    
    let query = ChatQuery(messages: [ .user(.init(content: .string(prompt))) ],
                          model: promptModel,
                          maxCompletionTokens: 2000,
                          responseFormat: .derivedJsonSchema(name: "plantuml result",
                                                             type: PlantUMLResult.self))
    
    let chatResult = try await openAI.chats(query: query)
    
    guard let content = chatResult.choices[0].message.content  else {
        throw _EX( "invalid result!" )
    }
    
    let result =  try plantumlOutputParse(content)
    
    return [ "diagram_code": result.script ]

}


func translateDiagramDescriptionToPlantUML<T:AgentExecutorDelegate>( state: AgentExecutorState,
                                                                     openAI:OpenAI,
                                                                     promptModel: String,
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
   
    let query = ChatQuery(messages: [ .system(.init(content: prompt)) ],
                          model: promptModel,
                          maxCompletionTokens: 2000,
                          responseFormat: .derivedJsonSchema(name: "plantuml result",
                                                             type: PlantUMLResult.self))

    let chatResult = try await openAI.chats(query: query)
    
    guard let content = chatResult.choices[0].message.content else {
        throw _EX( "invalid result!" )
    }

    let result =  try plantumlOutputParse(content)
    
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

public func runTranslateDrawingToPlantUML<T:AgentExecutorDelegate>( openAI: OpenAI,
                                                                    visionModel: String,
                                                                    promptModel: String,
                                                                    imageValue: DiagramImageValue,
                                                                    delegate:T ) async throws -> String? {
    
    let workflow = StateGraph { AgentExecutorState($0) }
    
    try workflow.addNode("agent_describer", action: { state in
        try await describeDiagramImage(state: state,
                                       openAI: openAI,
                                       visionModel: visionModel,
                                       delegate: delegate)
    })
    try workflow.addNode("agent_sequence_plantuml", action: { state in
        try await translateSequenceDiagramDescriptionToPlantUML( state: state,
                                                                 openAI:openAI,
                                                                 promptModel: promptModel,
                                                                 delegate:delegate )
    })
    try workflow.addNode("agent_usecase_plantuml", action: { state in
         try await translateDiagramDescriptionToPlantUML( state: state,
                                                          openAI:openAI,
                                                          promptModel: promptModel,
                                                          delegate:delegate )
    })
    try workflow.addNode("agent_generic_plantuml", action: { state in
         try await translateDiagramDescriptionToPlantUML( state: state,
                                                          openAI:openAI,
                                                          promptModel: promptModel,
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


public func updatePlantUML( openAI: OpenAI,
                            withModel model: Model,
                            input: String,
                            withInstruction instruction: String ) async throws -> String? {
    
    let system_prompt = try loadPromptFromBundle(fileName: "update_diagram_prompt")
    
    let query = ChatQuery(messages: [
            .system( .init(content: system_prompt)),
            .assistant(.init( content: input)),
            .user(.init(content: .string(instruction))) ],
                          model: model,
                          responseFormat: .derivedJsonSchema(name: "plantuml result",
                                                             type: PlantUMLResult.self),
                          temperature: 0.0,
                          topP: 1.0)

    let chat = try await openAI.chats(query: query)

    if let content = chat.choices[0].message.content {
        
        let result = try plantumlOutputParse(content)
        
        return result.script
    }
    
    return nil

}
