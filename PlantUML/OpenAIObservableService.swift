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
import AIAgent


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
    func updatePlantUMLDiagram( input: String, instruction: String ) async -> String? {
        
        guard let openAI /*, let  openAIModel */, case .Ready = status else {
            return nil
        }
        
        self.status = .Editing
        
        do {
            
            if let content = try await updatePlantUML(openAI: openAI,
                                                      withModel: openAIModel,
                                                      input: input,
                                                      withInstruction: instruction) {
                
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

// LangGraph Exstension
extension OpenAIObservableService {
    
    @MainActor
    func processImageWithAgents<T:AgentExecutorDelegate>( imageUrl: String, delegate:T ) async -> String? {
        
        guard let openAI, case .Ready = status else {
            delegate.progress("WARNING: OpenAI API not initialized")
            return nil
        }

        status = .Editing
        
        do {
            
            if DEMO_MODE {
                if let content = try await runTranslateDrawingToPlantUMLDemo( openAI: openAI, imageUrl: imageUrl, delegate:delegate) {
                    
                    status = .Ready
                    
                    return content
                        .split( whereSeparator: \.isNewline )
                        .filter { $0 != "@startuml" && $0 != "@enduml" }
                        .joined(separator: "\n" )
                }
            }
            else {
                if let content = try await runTranslateDrawingToPlantUML( openAI: openAI, imageUrl: imageUrl, delegate:delegate) {
                    
                    status = .Ready
                    
                    return content
                        .split( whereSeparator: \.isNewline )
                        .filter { $0 != "@startuml" && $0 != "@enduml" }
                        .joined(separator: "\n" )
                }
            }
            delegate.progress("ERROR: invalid result!")
            status = .Error( "invalid result!" )
        }
        catch {
            
            delegate.progress("ERROR: \(error.localizedDescription)")
            status = .Error( error.localizedDescription )
        }

        return nil
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
