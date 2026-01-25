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

/// Enum for selecting the AI Provider
enum AIProvider: String, CaseIterable, Identifiable {
    case openAI = "OpenAI"
    case ollama = "Ollama"
    //case gemini = "Gemini"
    
    var id: String { rawValue }
}



class AIObservableService : ObservableObject {
    
    enum Status : Equatable {
        case Ready
        case Error( String )
        case Processing
    }

    @Published public var status: Status = .Ready
    @Published public var inputApiKey = ""
    @Published public var provider: AIProvider = .openAI
    
    @AppStorage("aiProvider") var providerSetting:String = "OpenAI"
    @AppSecureStorage("openaikey") private var openAIKeySetting:String?
    @AppStorage("openaiModel") var openaiPromptModel:String = "gpt-4o-mini"
    @AppStorage("visionModel") var openaivisionModel:String = "gpt-4o"
    
    
    @AppStorage("ollamaPromptModel") var ollamaPromptModel:String = ""
    @AppStorage("ollamaVisionModel") var ollamaVisionModel:String = ""
    @AppStorage("ollamaURL")var ollamaURL: String = OllamaLanguageModel.defaultBaseURL.absoluteString

    var clipboardQueue  = LILOFixedSizeQueue<String>( maxSize: 10 )
    var promptQueue     = LILOFixedSizeQueue<String>( maxSize: 10 )
    
    
    init() {
        
        if let provider = UserDefaults.standard.string(forKey: "aiProvider") {
            self.providerSetting = provider
        }
        if let apiKey = readConfigString(forInfoDictionaryKey: "OPENAI_API_KEY"), !apiKey.isEmpty {
            self.openAIKeySetting = apiKey
        }
        
        self.provider = AIProvider(rawValue: self.providerSetting) ?? .openAI
        
        self.inputApiKey = self.openAIKeySetting ?? ""
        
        
     }
    
    func commitSettings() {
        if( self.provider.rawValue != self.providerSetting ) {
            self.providerSetting = self.provider.rawValue
        }
        
        if( self.inputApiKey != self.openAIKeySetting ) {
            self.openAIKeySetting = self.inputApiKey
        }

        if !self.inputApiKey.isEmpty {
            status = .Ready
        }
        
    }
    
    func rollbackSettings() {
        if( self.provider.rawValue != self.providerSetting ) {
            self.provider = AIProvider( rawValue: self.providerSetting ) ?? .openAI
        }
        
        if( self.inputApiKey != self.openAIKeySetting ) {
            self.inputApiKey = self.openAIKeySetting ?? ""
        }
    }

    var isSettingsValid:Bool {
        guard let openAIKeySetting, !openAIKeySetting.isEmpty else {
            return false
        }
        return true
    }

    @MainActor
    func updatePlantUMLDiagram( input: String, instruction: String ) async -> String? {
        
        guard let openAIKeySetting, case .Ready = status else {
            return nil
        }
        
        //print( "promptModel: \(promptModel)")
        self.status = .Processing
        
        do {
            let promptLanguageModel: any LanguageModel = switch( provider ) {
                case .ollama:
                    OllamaLanguageModel(baseURL: URL(string: ollamaURL)!, model: ollamaPromptModel)
                default:
                    OpenAILanguageModel(apiKey: openAIKeySetting, model: openaiPromptModel)
                }
            
            if let content = try await updatePlantUML( languageModel: promptLanguageModel,
                                                       input: input,
                                                       withInstruction: instruction,
                                                       supportStructuredOutput: provider == .openAI)
            {
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
extension AIObservableService {
    
    @MainActor
    func processImageWithAgents<T:AgentExecutorDelegate>( imageData: Data, delegate:T ) async -> String? {
        
        guard let openAIKeySetting, case .Ready = status else {
            delegate.progress("WARNING: OpenAI API not initialized")
            return nil
        }

        status = .Processing
        
        do {
            print( "promptModel: \(openaiPromptModel) - visionModel: \(openaivisionModel)")

            let promptLanguageModel = OpenAILanguageModel(apiKey: openAIKeySetting, model: openaiPromptModel)
            let visionLanguageModel = OpenAILanguageModel(apiKey: openAIKeySetting, model: openaivisionModel)

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

