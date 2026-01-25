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

/// Enum for selecting the AI Provider
enum AIProvider: String, CaseIterable, Identifiable {
    case openAI = "OpenAI"
    //case ollama = "Ollama"
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

//    @AppStorage("aiProvider") var providerSetting:String = "OpenAI"
    @AppSecureStorage("openaikey") private var openAIKeySetting:String?
    @AppStorage("openaiModel") var promptModel:String = "gpt-4o-mini"
    @AppStorage("visionModel") var visionModel:String = "gpt-4o"

    var clipboardQueue = LILOFixedSizeQueue<String>( maxSize: 10 )
    var promptQueue = LILOFixedSizeQueue<String>( maxSize: 10 )
    
    
    init() {
        
//        if let provider = UserDefaults.standard.string(forKey: "aiProvider") {
//            self.providerSetting = provider
//        }
        if let apiKey = readConfigString(forInfoDictionaryKey: "OPENAI_API_KEY"), !apiKey.isEmpty {
            self.openAIKeySetting = apiKey
        }
        
//        self.provider = AIProvider(rawValue: self.providerSetting) ?? .openAI
        
        self.inputApiKey = self.openAIKeySetting ?? ""

     }
    
    func commitSettings() {
//        if( self.provider.rawValue != self.providerSetting ) {
//            self.providerSetting = self.provider.rawValue
//        }
        
        if( self.inputApiKey != self.openAIKeySetting ) {
            self.openAIKeySetting = self.inputApiKey
        }

        if !self.inputApiKey.isEmpty {
            status = .Ready
        }
        
    }
    
    func rollbackSettings() {
//        if( self.provider.rawValue != self.providerSetting ) {
//            self.provider = AIProvider( rawValue: self.providerSetting ) ?? .openAI
//        }
        
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

    var openAI: OpenAI? {

        guard let openAIKeySetting  else {
            status = .Error("api key not found!")
            return nil
        }
        let config = OpenAI.Configuration( token: openAIKeySetting )
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
                                                      withModel: promptModel,
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
extension AIObservableService {
    
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
                try runTranslateDrawingToPlantUMLUseCaseDemo( openAI: openAI,
                                                              promptModel: promptModel,
                                                              imageValue: DiagramImageValue.data(imageData),
                                                              delegate:delegate) :
                try runTranslateDrawingToPlantUML( openAI: openAI,
                                                   visionModel: visionModel,
                                                   promptModel: promptModel,
                                                   imageValue: DiagramImageValue.data(imageData),
                                                   delegate:delegate);

            
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
