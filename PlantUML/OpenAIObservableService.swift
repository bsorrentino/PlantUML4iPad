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
        case Processing
    }

    @Published public var status: Status = .Ready
    @Published public var inputApiKey = ""

    #if __USE_ORGID
    @Published public var inputOrgId = ""
    @AppSecureStorage("openaiorg") private var openAIOrg:String?
    #endif

    @AppSecureStorage("openaikey") private var openAIKey:String?
    @AppStorage("openaiModel") private var openAIModel:String = "gpt-3.5-turbo"
    @AppStorage("visionModel") private var visionModel:String = "gpt-4o"

    var clipboardQueue = LILOFixedSizeQueue<String>( maxSize: 10 )
    var promptQueue = LILOFixedSizeQueue<String>( maxSize: 10 )
    
    
    init() {
        
        if let apiKey = readConfigString(forInfoDictionaryKey: "OPENAI_API_KEY"), !apiKey.isEmpty {
            openAIKey = apiKey
        }
        #if __USE_ORGID
        if let orgId = readConfigString(forInfoDictionaryKey: "OPENAI_ORG_ID"), !orgId.isEmpty  {
            openAIOrg = orgId
        }
        #endif
        
        inputApiKey = openAIKey ?? ""
        #if __USE_ORGID
        inputOrgId = openAIOrg ?? ""
        #endif
        
     }
    
    func commitSettings() {
        guard !inputApiKey.isEmpty else {
            return
        }
        openAIKey = inputApiKey
        #if __USE_ORGID
        guard !inputOrgId.isEmpty else {
            return
        }
        openAIOrg = inputOrgId
        #endif
        status = .Ready
    }
    
    func resetSettings() {
        inputApiKey = ""
        openAIKey = nil
        #if __USE_ORGID
        inputOrgId = ""
        openAIOrg = nil
        #endif
    }

    var isSettingsValid:Bool {
        #if __USE_ORGID
        guard let openAIKey, !openAIKey.isEmpty, let openAIOrg, !openAIOrg.isEmpty else {
            return false
        }
        #else
        guard let openAIKey, !openAIKey.isEmpty else {
            return false
        }
        #endif
        return true
    }

    var openAI: OpenAI? {

        guard let openAIKey  else {
            status = .Error("api key not found!")
            return nil
        }
        #if __USE_ORGID
        guard let openAIOrg  else {
            status = .Error("org id not found!")
            return nil
        }

        let config = OpenAI.Configuration( token: openAIKey, organizationIdentifier: openAIOrg)
        #else
        let config = OpenAI.Configuration( token: openAIKey )
        #endif
        return OpenAI( configuration: config )

    }

    @MainActor
    func updatePlantUMLDiagram( input: String, instruction: String ) async -> String? {
        
        guard let openAI /*, let  openAIModel */, case .Ready = status else {
            return nil
        }
        
        self.status = .Processing
        
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
    func processImageWithAgents<T:AgentExecutorDelegate>( imageData: Data, delegate:T ) async -> String? {
        
        guard let openAI, case .Ready = status else {
            delegate.progress("WARNING: OpenAI API not initialized")
            return nil
        }

        status = .Processing
        
        do {
            
            async let runTranslation = DEMO_MODE ?
                // try runTranslateDrawingToPlantUMLDemo( openAI: openAI, imageValue: DiagramImageValue.data(imageData), delegate:delegate) :
                try runTranslateDrawingToPlantUMLUseCaseDemo( openAI: openAI, imageValue: DiagramImageValue.data(imageData), delegate:delegate) :
            try runTranslateDrawingToPlantUML( openAI: openAI, imageValue: DiagramImageValue.data(imageData), delegate:delegate);

            
            if let content = try await runTranslation {
                
                status = .Ready
                
                return content
                    .split( whereSeparator: \.isNewline )
                    .filter { $0 != "@startuml" && $0 != "@enduml" }
                    .joined(separator: "\n" )
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
