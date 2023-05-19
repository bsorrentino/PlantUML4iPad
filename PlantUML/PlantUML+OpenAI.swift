//
//  PlantUML+OpenAI.swift
//  
//
//  Created by Bartolomeo Sorrentino on 29/03/23.
//

import SwiftUI
import OpenAIKit
import AppSecureStorage

extension PlantUMLContentView {
    
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
    
    enum Status {
        case Ready
        case Error( String )
        case Editing
    }
    
    @Published public var status: Status = .Ready
    
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
        
    }
//    lazy var openAI: OpenAI? = {
//
//        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String, !apiKey.isEmpty else {
//            status = .Error("api key not found!")
//            return nil
//        }
//        guard let orgId = Bundle.main.object(forInfoDictionaryKey: "OPENAI_ORG_ID") as? String, !orgId.isEmpty else {
//            status = .Error("org id not found!")
//            return nil
//        }
//
//        return OpenAI( Configuration(organizationId: orgId, apiKey: apiKey))
//
//    }()

    var openAI: OpenAI? {

        guard let openAIKey  else {
            status = .Error("api key not found!")
            return nil
        }
        guard let openAIOrg  else {
            status = .Error("org id not found!")
            return nil
        }

        return OpenAI( Configuration(organizationId: openAIOrg, apiKey: openAIKey))

    }

 
    @MainActor
    func generateEdit( input: String, instruction: String ) async -> String? {
        
        guard let openAI, case .Ready = status else {
            return nil
        }
        
        self.status = .Editing
        
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
    
    enum Tab {
        case Prompt
        case Result
        case PromptHistory
        case Settings
    }
    
    @ObservedObject var service:OpenAIService
    @Binding var result: String
    @State var instruction:String = ""
    @State private var tabs: Tab = .Prompt
    @State private var hideOpenAISecrets = true

    @AppSecureStorage("openaikey") private var openAIKey:String?
    @AppSecureStorage("openaiorg") private var openAIOrg:String?

    var isEditing:Bool {
        if case .Editing = service.status {
            return true
        }
        return false
    }
    
    var isSettingsValid:Bool {
        guard let openAIKey, let openAIOrg, !openAIKey.isEmpty, !openAIOrg.isEmpty else {
            return false
        }
        return true
    }
    
    var body: some View {
        
        VStack(spacing:0) {
            HStack(spacing: 10) {
                Button( action: { tabs = .Prompt } ) {
                    Label( "Prompt", systemImage: "")
                }
                .disabled( !isSettingsValid )

                Divider().frame(height: 20 )
                Button( action: { tabs = .PromptHistory } ) {
                    Label( "History", systemImage: "")
                }
                .disabled( !isSettingsValid )
                
                Divider().frame(height: 20 )
                Button( action: { tabs = .Result } ) {
                    Label( "Result", systemImage: "")
                }
                .disabled( !isSettingsValid )
                
                Divider().frame(height: 20 )
                Button( action: { tabs = .Settings } ) {
                    Label( "Settings", systemImage: "gearshape").labelStyle(.iconOnly)
                }
            }
            if case .Prompt = tabs {
                Prompt_Fragment
                    .frame( minHeight: 100 )
                    
            }
            if case .Result = tabs {
                Result_Fragment
                    .disabled( !isSettingsValid )
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
            if( !isSettingsValid ) {
                tabs = .Settings
            }
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
                            result = res
                        }
                    },
                    label: {
                        Label( "Undo", systemImage: "arrow.uturn.backward")
                            .labelStyle(.titleAndIcon)
                    })
                    .disabled( isEditing || service.clipboard.isEmpty )
                    
                    Button( action: {
                        
                        Task {
                            let input = "@startuml\n\(result)\n@enduml"
                            
                            if let res = await service.generateEdit( input: input, instruction: instruction ) {
                                service.status = .Ready
                                
                                service.clipboard.push( result )
                                
                                service.prompt.push( instruction )
                                
                                result = res
                                    .split( whereSeparator: \.isNewline )
                                    .filter { $0 != "@startuml" && $0 != "@enduml" }
                                    .joined(separator: "\n" )
                                
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
                Text( result )
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
        Form {
            Section {
                SecureToggleField( "Api Key", value: $openAIKey, hidden: hideOpenAISecrets)
                SecureToggleField( "Org Id", value: $openAIOrg, hidden: hideOpenAISecrets)
            }
            header: {
                HStack {
                    Text("OpenAI Secrets")
                    HideToggleButton(hidden: $hideOpenAISecrets)
                }
            }
            footer: {
                HStack {
                    Spacer()
                    Text("these data will be stored in onboard secure keychain")
                }
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
        OpenAIView( service: OpenAIService(),
                    result: Binding.constant(
                            """
                            @startuml
                            
                            @enduml
                            """))
        .frame(height: 200)
    }
}
