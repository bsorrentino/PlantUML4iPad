//
//  OpenAIService.swift
//  PlantUMLApp
//
//  Created by bsorrentino on 31/12/23.
//

import SwiftUI
import AppSecureStorage
import OpenAI
import PlantUMLFramework
import LangGraph


class OpenAIObservableService : ObservableObject {
    
    enum Status : Equatable {
        case Ready
        case Error( String )
        case Editing
    }

//    let models = ["text-davinci-edit-001", "code-davinci-edit-001"]
    
    @Published public var status: Status = .Ready
    @Published public var inputApiKey = ""
    @Published public var inputOrgId = ""
//    @Published public var inputModel:String

    @AppStorage("openaiModel") private var openAIModel:String = "gpt-3.5-turbo"
    @AppSecureStorage("openaikey") private var openAIKey:String?
    @AppSecureStorage("openaiorg") private var openAIOrg:String?

    var clipboardQueue = LILOFixedSizeQueue<String>( maxSize: 10 )
    var promptQueue = LILOFixedSizeQueue<String>( maxSize: 10 )
    
    
    init() {
        
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String, !apiKey.isEmpty {
            openAIKey = apiKey
        }
        if let orgId = Bundle.main.object(forInfoDictionaryKey: "OPENAI_ORG_ID") as? String, !orgId.isEmpty  {
            openAIOrg = orgId
        }
        
        inputApiKey = openAIKey ?? ""
        inputOrgId = openAIOrg ?? ""
        
//        inputModel = models[0]
                
//        if let openAIModel {
//            inputModel = openAIModel
//        }
        
     }
    
    func commitSettings() {
        guard !inputApiKey.isEmpty, !inputOrgId.isEmpty else {
            return
        }
        openAIKey = inputApiKey
        openAIOrg = inputOrgId
//        openAIModel = inputModel
        status = .Ready
    }
    
    func resetSettings() {
//        inputModel = models[0]
        inputApiKey = ""
        inputOrgId = ""
        openAIKey = nil
        openAIOrg = nil
    }

    var isSettingsValid:Bool {
        guard let openAIKey, !openAIKey.isEmpty, let openAIOrg, !openAIOrg.isEmpty else {
            return false
        }
        return true
    }

    var openAI: OpenAI? {

        guard let openAIKey  else {
            status = .Error("api key not found!")
            return nil
        }
        guard let openAIOrg  else {
            status = .Error("org id not found!")
            return nil
        }

        let config = OpenAI.Configuration( token: openAIKey, organizationIdentifier: openAIOrg)
        return OpenAI( configuration: config )

    }

    @MainActor
    func query( input: String, instruction: String ) async -> String? {
        
        guard let openAI /*, let  openAIModel */, case .Ready = status else {
            return nil
        }
        
        self.status = .Editing
        
        do {
            
            let query = ChatQuery(
                model: openAIModel,
                messages: [
                    .init(role: .system, content:
                                    """
                                    You are my plantUML assistant.
                                    You must answer exclusively with diagram syntax.
                                    """),
                    .init( role: .assistant, content: input ),
                    .init( role: .user, content: instruction )
                ],
                temperature: 0.0,
                topP: 1.0
            )

            let chat = try await openAI.chats(query: query)

            let result = chat.choices[0].message.content

            if case .string(let content) = result {
                
                status = .Ready
                
                return content
                    .split( whereSeparator: \.isNewline )
                    .filter { $0 != "@startuml" && $0 != "@enduml" }
                    .joined(separator: "\n" )
            }
            
            status = .Error( "invalid result!" )
            
            return nil

        }
        catch {
            
            status = .Error( error.localizedDescription )
            
            return nil
        }
    }
    
    @MainActor
    func vision( imageUrl: String ) async -> String? {
        
        guard let openAI /*, let  openAIModel */, case .Ready = status else {
            return nil
        }

        let prompt:String
        
        let result = loadPromptFromBundle(fileName: "vision_prompt_v3")
        switch( result ) {
            case .failure( let error ):
                status = .Error( error.localizedDescription )
                return nil
            case .success( let text ):
                prompt = text
        }
        
        
        let query = ChatQuery(
            model: .gpt4_vision_preview,
            messages: [
                Chat(role: .user, content: [
                    ChatContent(text: prompt),
                    ChatContent(imageUrl: imageUrl)
                ])
            ],
            maxTokens: 2000
        )
        
        status = .Editing
        
        do {
            let chatResult = try await openAI.chats(query: query)
            
            print( "=> FINISH REASON: \(chatResult.choices[0].finishReason ?? "UNKNOWN")")
            
            let result = chatResult.choices[0].message.content
           
            if case .string(let content) = result {
                status = .Ready
                
                return content
                    .split( whereSeparator: \.isNewline )
                    .filter { $0 != "@startuml" && $0 != "@enduml" }
                    .joined(separator: "\n" )
            }
            
            status = .Error( "invalid result!" )
            
            return nil
        }
        catch {
            
            status = .Error( error.localizedDescription )
            
            return nil
        }
    }

}

struct DiagramDescription : Codable {
    var type: String
}
struct AgentExecutorState : AgentState {
    var data: [String : Any]

    init() {
        data = [:]
    }
    
    init(_ initState: [String : Any]) {
        data = initState
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
extension OpenAIObservableService { // LangGraph extension
    
    func structuredOutpuParser( _ content: String ) -> DiagramDescription {
        return DiagramDescription(type: "generic")
    }
    
    func loadPromptFromBundle( fileName: String ) -> Result<String,Errors> {
        guard let filepath = Bundle.main.path(forResource: fileName, ofType: "txt") else {
            logger.error("prompt file \(fileName) not found!")
            return Result.failure(Errors.readingPromptError("prompt file \(fileName) not found!"))
        }

        do {
            let contents = try String(contentsOfFile: filepath, encoding: .utf8)
            return Result.success( contents )
        } catch {
            logger.error("Error reading the file: \(error)")
            return Result.failure( Errors.readingPromptError( "Error reading vision prompt" ) )
        }
    }

    func describeDiagramImage( state: AgentExecutorState ) async throws -> PartialAgentState {
        guard let openAI, case .Ready = status else {
            throw GraphRunnerError.executionError("OpenAI not initialized!")
        }
        guard let imageUrl = state.diagramImageUrlOrData else {
            throw GraphRunnerError.executionError("diagramImageUrlOrData not initialized!")
        }
        
        let prompt:String
        
        let result = loadPromptFromBundle(fileName: "vision_prompt")
        switch( result ) {
            case .failure( let error ):
                status = .Error( error.localizedDescription )
                throw GraphRunnerError.executionError(error.localizedDescription)
            case .success( let text ):
                prompt = text
                break
        }
        
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
        
        status = .Editing
        
        do {
            let chatResult = try await openAI.chats(query: query)
            
            let result = chatResult.choices[0].message.content
           
            if case .string(let content) = result {
                status = .Ready
                
                return [ "diagram": structuredOutpuParser( content ) ]
            }
            
            status = .Error( "invalid result!" )
            
        }
        catch {
            
            status = .Error( error.localizedDescription )
        }
        
        if case .Error( let msg ) = status  {
            throw GraphRunnerError.executionError(msg)
        }
        return [:]
        
        
    }
    func translateSequenceDiagramDescriptionToPlantUML( state: AgentExecutorState ) async throws -> PartialAgentState {
        
        return [:]
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

    @MainActor
    func agentExecutor( imageUrl: String ) async throws -> String? {
        
        let workflow = GraphState( stateType: AgentExecutorState.self )
        
        try workflow.addNode("agent_describer", action: describeDiagramImage )
        try workflow.addNode("agent_sequence_plantuml", action: translateSequenceDiagramDescriptionToPlantUML)
        try workflow.addNode("agent_gemeric_plantuml", action: translateGenericDiagramDescriptionToPlantUML)

        try workflow.addEdge(sourceId: "agent_sequence_plantuml", targetId: END)
        try workflow.addEdge(sourceId: "agent_gemeric_plantuml", targetId: END)
        
        try workflow.addConditionalEdge(
            sourceId: "agent_describer",
            condition: routeDiagramTranslation,
            edgeMapping: [
                "sequence": "agent_sequence_plantuml",
                "generic": "agent_gemeric_plantuml",
            ]
        )
        workflow.setEntryPoint( "agent_describer")

        let app = try workflow.compile()

        let imageToProcess = "" // getImageData( path.join( "assets", "diagram1.png" ))

        let inputs = [ "diagram_image_url_or_data": imageToProcess ]

        let response = try await app.invoke( inputs: inputs)

        print( response.diagramCode ?? "NONE")
        
        return response.diagramCode
    }
        

}

class LILOQueue<T> {
    
    var elements:Array<T> = []
    
    var isEmpty:Bool {
        elements.isEmpty
    }
    
    func push( _ item: T ) {
        elements.append( item )
    }
    
    func pop() -> T? {
        guard  !elements.isEmpty else {
            return nil
        }
        
        return elements.removeLast()
    }
    
    func clear() {
        elements.removeAll()
    }
    
}

class LILOFixedSizeQueue<T> : LILOQueue<T> {
    
    private let size:Int
    
    init( maxSize size: Int ) {
        self.size = size
    }
    
    override func push( _ item: T ) {
        if elements.count == size {
            elements.removeFirst()
        }
        elements.append( item )
    }
    
}
