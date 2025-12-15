//
//  OpenAIService.swift
//  PlantUMLApp
//
//  Created by bsorrentino on 31/12/23.
//

import SwiftUI
import AppSecureStorage
import AnyLanguageModel
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

    @AppSecureStorage("openaikey") private var openAIKey:String?
    @AppStorage("openaiModel") private var promptModel:String = "gpt-4o-mini"
    @AppStorage("visionModel") private var visionModel:String = "gpt-4o"

    var clipboardQueue = LILOFixedSizeQueue<String>( maxSize: 10 )
    var promptQueue = LILOFixedSizeQueue<String>( maxSize: 10 )
    
    
    init() {
        
        if let apiKey = readConfigString(forInfoDictionaryKey: "OPENAI_API_KEY"), !apiKey.isEmpty {
            openAIKey = apiKey
        }
        
        inputApiKey = openAIKey ?? ""
        
     }
    
    func commitSettings() {
        guard !inputApiKey.isEmpty else {
            return
        }
        openAIKey = inputApiKey
        status = .Ready
    }
    
    func resetSettings() {
        inputApiKey = ""
        openAIKey = nil
    }

    var isSettingsValid:Bool {
        guard let openAIKey, !openAIKey.isEmpty else {
            return false
        }
        return true
    }

    @MainActor
    func updatePlantUMLDiagram( input: String, instruction: String ) async -> String? {
        
        guard let openAIKey, case .Ready = status else {
            return nil
        }
        
        //print( "promptModel: \(promptModel)")
        self.status = .Processing
        
        do {
            let promptLanguageModel = OpenAILanguageModel(apiKey: openAIKey, model: promptModel)
            
            if let content = try await updatePlantUML( languageModel: promptLanguageModel,
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
        
        guard let openAIKey, case .Ready = status else {
            delegate.progress("WARNING: OpenAI API not initialized")
            return nil
        }

        status = .Processing
        
        do {
            print( "promptModel: \(promptModel) - visionModel: \(visionModel)")

            let promptLanguageModel = OpenAILanguageModel(apiKey: openAIKey, model: promptModel)
            let visionLanguageModel = OpenAILanguageModel(apiKey: openAIKey, model: visionModel)

            async let runTranslation = if DEMO_MODE  {
                try runTranslateDrawingToPlantUMLUseCaseDemo( promptModel: promptLanguageModel,
                                                              imageValue: DiagramImageValue.data(imageData),
                                                              delegate:delegate)
            }
            else {
                
                try runTranslateDrawingToPlantUML( visionModel: visionLanguageModel,
                                                   promptModel: promptLanguageModel,
                                                   imageValue: DiagramImageValue.data(imageData),
                                                   delegate:delegate);
            }
            
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
