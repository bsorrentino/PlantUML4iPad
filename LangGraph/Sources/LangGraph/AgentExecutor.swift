//
//  File.swift
//  
//
//  Created by bsorrentino on 12/03/24.
//

import Foundation
import OSLog
import OpenAI


@inline(__always) func _EX( _ msg: String ) -> GraphRunnerError {
    GraphRunnerError.executionError(msg)
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
struct DiagramDescription : Codable {
    var type: String
    var title: String
    var participants: [DiagramParticipant]
    var relations: [DiagramRelation]
    var containers: [DiagramContainer]
    var description: [String] // NLP description
}

struct AgentExecutorState : AgentState {
    
    var data: [String : Any]

    init() {
        data = [:]
    }
    
    init(_ initState: [String : Any]) {
        data = initState
    }
    
    var openAI:OpenAI? {
        data["openai"] as? OpenAI
    }
    
    var diagramImageUrlOrData:String? {
        data["diagram_image_url_or_data"] as? String
    }

    var diagramCode:String? {
        data["diagram_code"] as? String
    }

    var diagram:DiagramDescription? {
        data["diagram"] as? DiagramDescription
    }
}

func diagramDescriptionOutputParse( _ content: String ) throws -> DiagramDescription {
    
    let regex = #/```(json)?(?<code>.*[^`]{3})(```)?/#.dotMatchesNewlines()
    
    if let match = try regex.wholeMatch(in: content) {
        
        
        let decoder = JSONDecoder()
        
        let code = match.code
        
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

func describeDiagramImage( state: AgentExecutorState ) async throws -> PartialAgentState {
    
    guard let openAI = state.openAI else {
        throw _EX("OpenAI not initialized!")
    }
    guard let imageUrl = state.diagramImageUrlOrData else {
        throw _EX("diagramImageUrlOrData not initialized!")
    }
    
    let prompt = try loadPromptFromBundle(fileName: "describe_diagram_prompt")
    
    let query = ChatQuery(
        model: .gpt4_vision_preview,
        messages: [
            Chat(role: .user, content: [
                ChatContent(text: prompt),
                ChatContent(imageUrl: imageUrl )
            ])
        ],
        maxTokens: 2000
    )
    
    let chatResult = try await openAI.chats(query: query)
    
    let result = chatResult.choices[0].message.content
   
    if case .string(let content) = result {
        return [ "diagram": try diagramDescriptionOutputParse( content ) ]
    }
    
    throw _EX("invalid content")
}

func translateSequenceDiagramDescriptionToPlantUML( state: AgentExecutorState ) async throws -> PartialAgentState {
    
    guard let openAI = state.openAI else {
        throw _EX("OpenAI not initialized!")
    }
    guard let diagram = state.diagram else {
        throw _EX("diagram not initialized!")
    }
    
    var prompt = try loadPromptFromBundle(fileName: "sequence_diagram_prompt")

    prompt = prompt
        .replacingOccurrences(of: "{diagram_title}", with: diagram.title)
        .replacingOccurrences(of: "{diagram_description}", with: diagram.description.joined(separator: "\n"))

    let query = ChatQuery(
        model: .gpt3_5Turbo,
        messages: [
            Chat(role: .user, content: [
                ChatContent(text: prompt),
            ])
        ],
        maxTokens: 2000
    )
    
        let chatResult = try await openAI.chats(query: query)
        
        let result = chatResult.choices[0].message.content
       
        if case .string(let content) = result {
            return [ "diagram_code": content ]
            
        }
        
        throw _EX( "invalid result!" )
        
}

func translateGenericDiagramDescriptionToPlantUML( state: AgentExecutorState ) async throws -> PartialAgentState {
    
    return [:]
}

func routeDiagramTranslation( state: AgentExecutorState ) async throws -> String {
    
    guard let diagram = state.diagram else {
        throw GraphRunnerError.executionError("diagram is nil!")
    }
    if diagram.type == "sequence" {
        return "sequence"
    } else {
        return "generic"
    }
}

public func agentExecutor( openAI: OpenAI, imageUrl: String ) async throws -> String? {
    
    let workflow = GraphState( stateType: AgentExecutorState.self )
    
    try workflow.addNode("agent_describer", action: describeDiagramImage )
    try workflow.addNode("agent_sequence_plantuml", action: translateSequenceDiagramDescriptionToPlantUML)
    try workflow.addNode("agent_generic_plantuml", action: translateGenericDiagramDescriptionToPlantUML)

    try workflow.addEdge(sourceId: "agent_sequence_plantuml", targetId: END)
    try workflow.addEdge(sourceId: "agent_generic_plantuml", targetId: END)
    
    try workflow.addConditionalEdge(
        sourceId: "agent_describer",
        condition: routeDiagramTranslation,
        edgeMapping: [
            "sequence": "agent_sequence_plantuml",
            "generic": "agent_generic_plantuml",
        ]
    )
    workflow.setEntryPoint( "agent_describer")

    let app = try workflow.compile()

    let inputs:[String : Any] = [
        "openai": openAI,
        "diagram_image_url_or_data": imageUrl
    ] 

    let response = try await app.invoke( inputs: inputs)

    return response.diagramCode
}


