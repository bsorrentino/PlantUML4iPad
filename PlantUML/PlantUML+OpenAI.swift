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
            viewState.isOpenAIVisible.toggle()
        }
        label: {
            Label( "OpenAI Editor", systemImage: "brain" )
                .labelStyle(.iconOnly)
                .foregroundColor( viewState.isEditorVisible ? .blue : .gray)
        
        }
    }

}

class OpenAIService : ObservableObject {
    
    enum Status {
        case Ready
        case Error( String )
        case Editing
    }

    @Published public var status: Status = .Ready
    private (set) var clipboard: [String] = []
    
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
    
    func pushToClipboard( _ item: String ) {
        clipboard.append( item )
    }

    func popFromClipboard() -> String? {
        guard  !clipboard.isEmpty else {
            return nil
        }
        
        return clipboard.removeLast()
    }

    func generateEdit( input: String, instruction: String ) async -> String? {
        
        guard let openAI, case .Ready = status else {
            return nil
        }
        
        Task { @MainActor in
            self.status = .Editing
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
      
            let result = editResponse.choices[0].text
            
            return result
        }
        catch {
            status = .Error( error.localizedDescription )
            return nil
        }
    }
}

struct OpenAIView : View {
  
    @ObservedObject var service:OpenAIService
    @Binding var result: String
    @State var input:String = """
                              @startuml

                              @enduml
                              """
    @State var instruction:String = ""
    var onUndo:(() -> Void)
    
    var isEditing:Bool {
        if case .Editing = service.status {
            return true
        }
        return false
    }
    
    var body: some View {
        VStack {
            
            HStack {
                TextEditor(text: $instruction)
                    .font(.title3.monospaced() )
                    .lineSpacing(15)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .border(.gray, width: 1)
                    .padding()

                ScrollView {
                    Text( input )
                        .font( .system(size: 10.0, design: .monospaced) )
                }.padding()
            }
            
            HStack(spacing: 10) {
                Button( action: {
                    
                    Task {
                        if let res = await service.generateEdit( input: input, instruction: instruction ) {
                            service.status = .Ready
                            service.pushToClipboard( result )
                            result = res
                        }
                    }
                },
                label: {
                    if isEditing {
                        ProgressView("AI editing....")
                    }
                    else {
                        Label( "Submit", systemImage: "arrow.right")
                    }
                })
                .disabled( isEditing  )
                .padding( .bottom, 10 )
                                
                Button( action: onUndo,
                label: {
                    Label( "Undo", systemImage: "arrow.uturn.backward")
                        .labelStyle(.titleAndIcon)
                })
                .disabled( isEditing || service.clipboard.isEmpty )
                .padding( .bottom, 10 )
            }
            if case .Error( let err ) = service.status {
                Text( err )
                    .foregroundColor(.red)
            }
            
        }
        .frame( maxHeight: 300 )

    }
}

struct OpenAIView_Previews: PreviewProvider {
    
    struct Item : RawRepresentable {
        
        var rawValue: String
        
        typealias RawValue = String
        
        
    }
    static var previews: some View {
        OpenAIView( service: OpenAIService(),
                    result: Binding.constant(""),
                    onUndo: { } )
    }
}
