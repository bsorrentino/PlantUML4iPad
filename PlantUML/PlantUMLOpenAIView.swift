//
//  PlantUML+OpenAI.swift
//  PlantUMLApp
//
//  Created by Bartolomeo Sorrentino on 29/03/23.
//

import SwiftUI
import OpenAI

struct OpenAIView<DrawingView :View> : View {
    
    enum Tab {
        case Prompt
        case Result
        case PromptHistory
        case Settings
    }
    
    @ObservedObject var service:  OpenAIObservableService
    @ObservedObject var document: PlantUMLObservableDocument
    @EnvironmentObject var networkService: NetworkObservableService

    @State var instruction:String = ""
    @State private var tabs: Tab = .Prompt
    @State private var hideOpenAISecrets = true
    @State private var isDrawingPresented = false
    
    @FocusState private var promptInFocus: Bool
    
    var drawingView: () -> DrawingView
    
    var isEditing:Bool {
        if case .Processing = service.status {
            return true
        }
        return false
    }
    
    var body: some View {
        
        VStack(spacing:0) {
            HStack(spacing: 15) {
                
                Button( action: {
                    isDrawingPresented.toggle()
                }) {
                    Label( "Drawing", systemImage: "pencil.circle")
                }
                .accessibilityIdentifier("openai_drawing")
                .disabled( !service.isSettingsValid )
                
                
                Button( action: { tabs = .Prompt } ) {
                    Label( "Prompt", systemImage: "keyboard.onehanded.right")
                }
                .accessibilityIdentifier("openai_prompt")
                .disabled( !service.isSettingsValid )
                .networkEnabled( networkService )

//                Divider().frame(height: 20 )
                Button( action: { tabs = .PromptHistory } ) {
                    Label( "History", systemImage: "clock")
                }
                .accessibilityIdentifier("openai_history")
                .disabled( !service.isSettingsValid )
                
//                Divider().frame(height: 20 )
                Button( action: { tabs = .Result } ) {
                    Label( "Result", systemImage: "doc.plaintext")
                }
                .accessibilityIdentifier("openai_result")
                .disabled( !service.isSettingsValid )
                
                Divider()
                    .background( .blue)
                    .frame(height: 20 )
                Button( action: { tabs = .Settings } ) {
                    Label( "Settings", systemImage: "gearshape")
                        //.labelStyle(.iconOnly)
                }
                .accessibilityIdentifier("openai_settings")
            }
            if case .Prompt = tabs {
                Prompt_Fragment
                    .frame( minHeight: 100 )
                    
            }
            if case .Result = tabs {
                Result_Fragment
                    .disabled( !service.isSettingsValid )
            }
            if case .PromptHistory = tabs {
                HistoryPrompts_Fragment
            }
            if case .Settings = tabs {
                Settings_Fragment
            }
        }
        .padding( EdgeInsets(top: 0, leading: 5, bottom: 5, trailing: 0))
        .onAppear {
            if( !service.isSettingsValid ) {
                tabs = .Settings
            }
        }
        .fullScreenCover(isPresented: $isDrawingPresented ) {
            drawingView()
        }
        
    }
    
}

// MARK: Prompt Extension
extension OpenAIView {
    
    
    var Prompt_Fragment: some View {
        
        ZStack(alignment: .topTrailing ) {
            
            VStack(alignment: .leading) {
                
                if case .Error( let err ) = service.status {
                    Divider()
                    Text( err )
                        .foregroundColor(.red)
                }

                TextEditor(text: $instruction)
                    .font(.title3.monospaced() )
                    .lineSpacing(15)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding( .trailing, 25)
                    .padding( .bottom, 35)
                    .accessibilityIdentifier("openai_instruction")
                    .focused($promptInFocus)
                    .onChange(of: instruction) {
                        if service.status != .Ready {
                            service.status = .Ready
                        }
                    }
            }
            .border(.gray, width: 1)
            
            VStack(alignment:.trailing) {
                
                if !instruction.isEmpty {
                    Button( action: {
                        instruction = ""
                    },
                    label: {
                        Image( systemName: "x.circle")
                    })
                    .accessibilityIdentifier("openai_clear")
                }
                
                Spacer()
                
                HStack {
                    Button( action: {
                        if let res = service.clipboardQueue.pop() {
                            document.text = res
                        }
                    },
                    label: {
                        Label( "Undo", systemImage: "arrow.uturn.backward")
                            .labelStyle(.titleAndIcon)
                    })
                    .disabled( isEditing || service.clipboardQueue.isEmpty )
                    
                    Button( action: {
                        
                        Task {
                            let input = "@startuml\n\(document.text)\n@enduml"
                            
                            if let queryReult = await service.updatePlantUMLDiagram( input: input, instruction: instruction ) {
                                
                                service.clipboardQueue.push( document.text )
                                
                                service.promptQueue.push( instruction )
                                
                                document.text = queryReult
                                    
                            }
                        }
                    },
                    label: {
                        if isEditing {
                            ProgressView()
                        }
                        else {
                            Label( "Submit", systemImage: "arrow.right")
                        }
                    })
                    .disabled( isEditing )
                    .accessibilityIdentifier("openai_submit")
                    .networkEnabled(networkService)
                }
            }
            .padding(EdgeInsets( top: 10, leading: 0, bottom: 5, trailing: 10))
        }
        .padding()
    }
    
}

// MARK: History Extension
extension OpenAIView {
    
    var HistoryPrompts_Fragment: some View {
        
        HStack {
            List( service.promptQueue.elements, id: \.self ) { prompt in
                HStack {
                    Text( prompt )
                    CopyToClipboardButton( value: prompt )
                }
            }
        }
        .border(.gray)
        .padding()

    }
    
}

// MARK: Result Extension
extension OpenAIView {
    
    var Result_Fragment: some View {
        HStack {
            Spacer()
            ScrollView {
                Text( document.text )
                    .font( .system(size: 14.0, design: .monospaced) )
                    .padding()
            }
            Spacer()
        }
        .border(.gray)
        .padding()
    }
    
}

// MARK: Settings Extension
extension OpenAIView {
   
    var Settings_Fragment: some View {
        ZStack(alignment: .bottomTrailing ) {
            // [How to scroll a Form to a specific UI element in SwiftUI](https://stackoverflow.com/a/65777080/521197)
            ScrollViewReader { p in
                Form {
                    Section {
                        SecureToggleField( "Api Key", value: $service.inputApiKey, hidden: hideOpenAISecrets)
                        #if __USE_ORGID
                        SecureToggleField( "Org Id", value: $service.inputOrgId, hidden: hideOpenAISecrets)
                        #endif
                    }
                    header: {
                        HStack {
                            Text("OpenAI Secrets")
                            HideToggleButton(hidden: $hideOpenAISecrets)
                        }
                        .id( "openai-secret")
                        
                    }
                    footer: {
                        HStack {
                            Spacer()
                            Text("these data will be stored in onboard secure keychain")
                            Spacer()
                        }
                    }
                                        
                }
            }
            HStack {
                Button( action: {
                    service.resetSettings()
                },
                label: {
                    Label( "Clear", systemImage: "xmark")
                })
                Button( action: {
                    service.commitSettings()
                    tabs = .Prompt
                    promptInFocus = true
                    
                },
                label: {
                    Label( "Save", systemImage: "arrow.right")
                })
                #if __USE_ORGID
                .disabled( service.inputApiKey.isEmpty || service.inputOrgId.isEmpty )
                #else
                .disabled( service.inputApiKey.isEmpty )
                #endif
            }
            .padding()
        }
        
    }
    
}





#Preview {
    struct FullScreenModalView: View {
        @Environment(\.dismiss) var dismiss

        var body: some View {
            ZStack {
                Color.primary.edgesIgnoringSafeArea(.all)
                Button("Dismiss Modal") {
                    dismiss()
                }
            }
        }
    }

    struct Item : RawRepresentable {
        
        var rawValue: String
        
        typealias RawValue = String
        
        
    }
    
    return OpenAIView( service: OpenAIObservableService(),
                       document: PlantUMLObservableDocument(
                            document:.constant(PlantUMLDocument(text: """
                        @startuml
                        
                        @enduml
                        """)), fileName:"Untitled"),
                       drawingView: {
                            FullScreenModalView()
                        })
            .frame(height: 200)
}
