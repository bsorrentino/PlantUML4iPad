//
//  SwiftUIView.swift
//  
//
//  Created by Bartolomeo Sorrentino on 29/03/23.
//

import SwiftUI
import OpenAIKit

extension PlantUMLContentView {
    func ToggleOpenAIButton() -> some View {
        
        Button {
            isOpenAIVisible.toggle()
        }
        label: {
            Label( "OpenAI Editor", systemImage: "brain" )
                .labelStyle(.iconOnly)
                .foregroundColor( isEditorVisible ? .blue : .gray)
        
        }
    }

}

class OpenAIService : ObservableObject {
    
    enum Status {
        case Ready
        case Error( String )
        case Editing
    }

    public var status: Status = .Ready
    
    lazy var openAI: OpenAI? = {
        
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String, !apiKey.isEmpty else {
            status = .Error("api key not found!")
            return nil
        }
        guard let orgId = Bundle.main.object(forInfoDictionaryKey: "OPENAI_ORG_ID") as? String, !orgId.isEmpty else {
            status = .Error("org id not found!")
            return nil
        }

        return OpenAI( Configuration(organizationId: orgId, apiKey: apiKey))

    }()

    func generateEdit( input: String, instruction: String ) async -> String? {
        
        guard let openAI, case .Ready = status else {
            return nil
        }

        Task { @MainActor in
            status = .Editing
        }
        
        do {
            let editParameter = EditParameters(
                model: "text-davinci-edit-001",
                input: input,
                instruction: instruction,
                temperature: 0.0,
                topP: 1.0
            )
            
            let editResponse = try await openAI.generateEdit(parameters: editParameter)
      
            Task { @MainActor in
                status = .Ready
            }
            return editResponse.choices[0].text
        }
        catch {
            status = .Error( error.localizedDescription )
            return nil
        }
    }
}

struct OpenAIView : View {
  
    @StateObject var service = OpenAIService()
    @Binding var result: String
    @State var input:String = """
                              @startuml

                              @enduml
                              """
    @State var instruction:String = ""
    
    var body: some View {
        VStack {
            TextEditor(text: $instruction)
                .font(.title2)
                .lineSpacing(20)
                .autocapitalization(.words)
                .disableAutocorrection(true)
                .border(.green, width: 1)
                .padding()
            
            Button( action: {
                Task {
                    if let res = await service.generateEdit( input: input, instruction: instruction ) {
                        result = res
                    }
                }
            },
            label: {
                Label( "Submit", systemImage: "brain")
            })
            if case .Error( let err ) = service.status {
                Divider()
                Text( err )
            }
            else {
                Text( input )
            }
        }

    }
}

struct OpenAIView_Previews: PreviewProvider {
    
    struct Item : RawRepresentable {
        
        var rawValue: String
        
        typealias RawValue = String
        
        
    }
    static var previews: some View {
        OpenAIView( result: Binding.constant("") )
    }
}
