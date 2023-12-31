//
//  PlantUML+OpenAI.swift
//  PlantUMLApp
//
//  Created by Bartolomeo Sorrentino on 29/03/23.
//

import SwiftUI
import OpenAI
import AppSecureStorage

extension PlantUMLDocumentView {
    
    var ToggleOpenAIButton: some View {
        
        Button {
            isOpenAIVisible.toggle()
        }
        label: {
            Label {
                Text("OpenAI Editor")
            } icon: {
                #if __OPENAI_LOGO
                // [How can I set an image tint in SwiftUI?](https://stackoverflow.com/a/73289182/521197)
                Image("openai")
                    .resizable()
                    .colorMultiply(isOpenAIVisible ? .blue : .gray)
                    .frame( width: 28, height: 28)
                #else
                Image( systemName: "brain" )
                    .resizable()
                    .foregroundColor( isOpenAIVisible ? .blue : .gray)
                    .frame( width: 24, height: 20)
                #endif
            }
            .environment(\.symbolVariants, .fill)
            .labelStyle(.iconOnly)
        }
        .accessibilityIdentifier("openai")
    }
    
}

class LILOQueue<T> {
    
    fileprivate var elements:Array<T> = []
    
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

class OpenAIService : ObservableObject {
    
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

    fileprivate var clipboard = LILOFixedSizeQueue<String>( maxSize: 10 )
    fileprivate var prompt = LILOFixedSizeQueue<String>( maxSize: 10 )
    
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

        let prompt =
        """
        Translate diagram within image in a plantUML script following rules below:

        1. if detect rectangle it must be translate in plantuml rectangle element with related label if any
        2. if detect rectangle that contains other rectangles must be translated in plantuml rectangle {}  element
        3. for any other shapes translate it in the most opportune plantuml element
        4. every label (word or phrase) outside shapes: if close to arrow must be considered its label else it must be translated in plantuml note
        
        result must be:
            1. in plain text format no markdown allowed
            2. contain only the plantuml script without any other comment
        """
        
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


struct OpenAIView<DrawingView :View> : View {
    
    enum Tab {
        case Prompt
        case Result
        case PromptHistory
        case Settings
    }
    
    @ObservedObject var service:OpenAIService
    @ObservedObject var document: PlantUMLDocumentProxy
    @State var instruction:String = ""
    @State private var tabs: Tab = .Prompt
    @State private var hideOpenAISecrets = true
    @State private var isDrawingPresented = false
    
    @FocusState private var promptInFocus: Bool
    
    var drawingView: () -> DrawingView
    
    var isEditing:Bool {
        if case .Editing = service.status {
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
                .accessibilityIdentifier("openai_prompt")
                .disabled( !service.isSettingsValid )
                
                Button( action: { tabs = .Prompt } ) {
                    Label( "Prompt", systemImage: "keyboard.onehanded.right")
                }
                .accessibilityIdentifier("openai_prompt")
                .disabled( !service.isSettingsValid )

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
                        if let res = service.clipboard.pop() {
                            document.text = res
                        }
                    },
                    label: {
                        Label( "Undo", systemImage: "arrow.uturn.backward")
                            .labelStyle(.titleAndIcon)
                    })
                    .disabled( isEditing || service.clipboard.isEmpty )
                    
                    Button( action: {
                        
                        Task {
                            let input = "@startuml\n\(document.text)\n@enduml"
                            
                            if let queryReult = await service.query( input: input, instruction: instruction ) {
                                
                                service.clipboard.push( document.text )
                                
                                service.prompt.push( instruction )
                                
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
            List( service.prompt.elements, id: \.self ) { prompt in
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
                            
                        SecureToggleField( "Org Id", value: $service.inputOrgId, hidden: hideOpenAISecrets)
                    }
                    header: {
                        HStack {
                            Text("OpenAI Secrets")
                            HideToggleButton(hidden: $hideOpenAISecrets)
//                            Divider()
//                            Button( action: { p.scrollTo("openai-settings", anchor: .top) }, label: { Text("More .....").font(.footnote) } )
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
                    
//                    Section {
//                        Picker("Model", selection: $service.inputModel) {
//                            ForEach(service.models, id: \.self) {
//                                Text($0)
//                            }
//                        }
//                    }
//                    header: {
//                        HStack {
//                            Text("OpenAI Extra settings")
//                            Divider()
//                            Button( action: { p.scrollTo("openai-secret", anchor: .bottom) }, label: { Text("Back ...").font(.footnote) } )
//                        }
//                        .id( "openai-settings")
//                    }
//                    footer: {
//                        Rectangle().fill(Color.clear).frame(height: 65)
//
//                    }
                    
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
                    Label( "Submit", systemImage: "arrow.right")
                })
                .disabled( service.inputApiKey.isEmpty || service.inputOrgId.isEmpty )
                
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
    
    return OpenAIView( service: OpenAIService(),
                       document: PlantUMLDocumentProxy(
                            document:.constant(PlantUMLDocument(text: """
                        @startuml
                        
                        @enduml
                        """)), fileName:"Untitled"),
                       drawingView: {
                            FullScreenModalView()
                        })
            .frame(height: 200)
}
