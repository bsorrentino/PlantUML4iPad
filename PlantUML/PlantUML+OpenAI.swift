//
//  PlantUML+OpenAI.swift
//  
//
//  Created by Bartolomeo Sorrentino on 29/03/23.
//

import SwiftUI
import OpenAIKit

extension PlantUMLContentView {
    
    var ToggleOpenAIButton: some View {
        
        Button {
            isOpenAIVisible.toggle()
        }
        label: {
            Label( "OpenAI Editor", systemImage: "brain" )
                .environment(\.symbolVariants, .fill)
                .labelStyle(.iconOnly)
                .foregroundColor( isOpenAIVisible ? .blue : .gray)
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
    fileprivate var clipboard = LILOFixedSizeQueue<String>( maxSize: 10 )
    fileprivate var prompt = LILOFixedSizeQueue<String>( maxSize: 10 )
    
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
        case Input
        case Result
        case Prompt
    }
    
    @ObservedObject var service:OpenAIService
    @Binding var result: String
    @State var instruction:String = ""
    @State private var tabs: Tab = .Input
    
    var isEditing:Bool {
        if case .Editing = service.status {
            return true
        }
        return false
    }
    
    var body: some View {
        
        VStack(spacing:0) {
            HStack(spacing: 10) {
                Button( action: { tabs = .Input } ) {
                    Label( "OpenAI", systemImage: "")
                }
                Divider().frame(height: 20 )
                Button( action: { tabs = .Prompt } ) {
                    Label( "Prompt", systemImage: "")
                }
                Divider().frame(height: 20 )
                Button( action: { tabs = .Result } ) {
                    Label( "Result", systemImage: "")
                }
            }
            if case .Input = tabs {
                Input_Fragment
                    .frame( minHeight: 100 )
            }
            if case .Result = tabs {
                Result_Fragment
            }
            if case .Prompt = tabs {
                Prompt_Fragment
            }
        }
        .padding( EdgeInsets(top: 0, leading: 5, bottom: 5, trailing: 0))
        
    }
    
}

// MARK: Input Extension
extension OpenAIView {
    
    var Input_Fragment: some View {
        
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

// MARK: Prompt Extension
extension OpenAIView {
    
    var Prompt_Fragment: some View {
        
        List( service.prompt.elements, id: \.self ) { prompt in
            HStack {
                Text( prompt )
                CopyToClipboardButton( value: prompt )
            }
        }
    }
    
}

// MARK: Result Extension
extension OpenAIView {
    
    var Result_Fragment: some View {
        
        ScrollView {
            Text( result )
                .font( .system(size: 14.0, design: .monospaced) )
        }
        .padding()
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
