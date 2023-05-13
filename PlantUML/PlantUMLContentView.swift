//
//  PlantUMLContentView.swift
//  PlantUML
//
//  Created by Bartolomeo Sorrentino on 01/08/22.
//

import SwiftUI
import Combine
import PlantUMLFramework
import PlantUMLKeyboard
import LineEditor

//
// [Managing Focus in SwiftUI List Views](https://peterfriese.dev/posts/swiftui-list-focus/)
//
//  enum Focusable: Hashable {
//      case none
//      case row(id: String)
//  }


struct PlantUMLContentView: View {
    typealias PlantUMLLineEditorView = StandardLineEditorView<Symbol>
    
    @Environment(\.scenePhase) var scene
    @Environment(\.interfaceOrientation) var interfaceOrientation: InterfaceOrientationHolder
    @Environment(\.editMode) private var editMode
    @Environment(\.openURL) private var openURL
    
    @StateObject var document: PlantUMLDocumentProxy
    @StateObject private var openAIService = OpenAIService()
    
    @State private var isEditorVisible  = true
    //@State private var isPreviewVisible = false
    private var isDiagramVisible:Bool { !isEditorVisible}
    @State var isOpenAIVisible  = false
    
    @State var keyboardTab: String  = "general"
    @State private var isScaleToFit = true
    @State private var fontSize = CGFloat(12)
    @State private var showLine:Bool = false
    @State private var saving = false
    @State private var diagramImage:UIImage?
    
    var body: some View {
        
        VStack {
            GeometryReader { geometry in
                if( isEditorVisible ) {
                    EditorView_Fragment
                }
                
                if isDiagramVisible {
                    if isScaleToFit {
                        PlantUMLDiagramViewFit
                            .frame( width: geometry.size.width, height: geometry.size.height )
                    }
                    else {
                        ScrollView([.horizontal, .vertical], showsIndicators: true) {
                            PlantUMLDiagramView( url: document.buildURL(), contentMode: .fill )
                                .frame( minWidth: geometry.size.width)
                        }
                        .frame( minWidth: geometry.size.width, minHeight: geometry.size.height )
                    }
                }
            }
            if isOpenAIVisible && interfaceOrientation.value.isPortrait {
                OpenAIView_Fragment
                    .frame( height: 200 )
            }
        }
        .onChange(of: document.text ) { _ in
            saving = true
            document.updateRequest.send()
        }
        .onReceive(document.updateRequest.publisher) { _ in
            withAnimation(.easeInOut(duration: 1.0)) {
                document.save()
                saving = false
            }
        }
        .onRotate(perform: { orientation in
            if  (orientation.isPortrait && isDiagramVisible) ||
                    (orientation.isLandscape && isEditorVisible)
            {
                isEditorVisible.toggle()
            }
        })
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                HStack( spacing: 0 ) {
                    SavingStateView( saving: saving )
                    
                    if interfaceOrientation.value.isPortrait {
                        HStack(alignment: .center, spacing: 5) {
                            ToggleOpenAIButton
                            Divider().background(Color.blue)
                        }
                        .frame(height:20)
                    }

                    ToggleEditorButton()
                    if isEditorVisible {
                        HStack {
                            EditButton()
                            fontSizeView()
                            toggleLineNumberView()
                        }
                    }
                    
                    ToggleDiagramButton()
                    if isDiagramVisible {
                        ScaleToFitButton()
                        ShareDiagramButton()
                    }
                }
            }
        }
    }
}

//
// MARK: - OpenAI extension -
//
extension PlantUMLContentView {
    
    var OpenAIView_Fragment: some View {
        
        OpenAIView( service: openAIService, result: $document.text )
        
    }
    
}

//
// MARK: - Editor extension -
//
extension PlantUMLContentView {
    
    var EditorView_Fragment: some View {
        
        PlantUMLLineEditorView( text: $document.text,
                                fontSize: $fontSize,
                                showLine: $showLine) { onHide, onPressSymbol in
            PlantUMLKeyboardView( selectedTab: $keyboardTab,
                                  onHide: onHide,
                                  onPressSymbol: onPressSymbol)
        }
    }
    
    // [SwiftUI Let View disappear automatically](https://stackoverflow.com/a/60820491/521197)
    struct SavedStateView: View {
        @Binding var visible: Bool
        let timer = Timer.publish(every: 5.0, on: .main, in: .common).autoconnect()
        
        var body: some View {
            
            Text("_saved_" )
                .onReceive(timer) { _ in
                    withAnimation {
                        self.visible.toggle()
                    }
                }
                .transition( AnyTransition.asymmetric(insertion: .scale, removal: .opacity))
        }
    }
    
    struct SavingStateView: View {
        var saving:Bool
        @State private var visible = false
        
        var body: some View {
            HStack(alignment: .bottom, spacing: 5) {
                if( saving ) {
                    ProgressView()
                    Text( "_saving..._")
                        .onAppear {
                            visible = true
                        }
                }
                else {
                    if visible {
                        PlantUMLContentView.SavedStateView( visible: $visible )
                    }
                }
            }
            .foregroundColor(Color.secondary)
            .frame( maxWidth: 100 )
        }
        
    }
    
    func toggleLineNumberView() -> some View {
        Button( action: { showLine.toggle() } ) {
            Image( systemName: "list.number")
        }
        
    }
    
    func fontSizeView() -> some View {
        HStack( spacing: 0 ) {
            Button( action: { fontSize += 1 } ) {
                Image( systemName: "textformat.size.larger")
            }
            .accessibilityIdentifier("font+")
            Divider()
                .background(Color.blue)
                .frame(height:20)
                .padding( .leading, 5)
            Button( action: { fontSize -= 1} ) {
                Image( systemName: "textformat.size.smaller")
            }
            .accessibilityIdentifier("font-")
        }
    }
    
    func ToggleEditorButton() -> some View {
        
        Button {
            if !isEditorVisible {
                withAnimation {
                    diagramImage = nil // avoid popup of share image UIActivityViewController
                    isEditorVisible.toggle()
                }
            }
        }
    label: {
        Label( "Toggle Editor", systemImage: "doc.plaintext.fill" )
            .labelStyle(.iconOnly)
            .foregroundColor( isEditorVisible ? .blue : .gray)
    }
    .accessibilityIdentifier("editor")
        
    }
    
    @available(swift, obsoleted: 1.1,message: "from 1.1 auto save has been introduced")
    func SaveButton() -> some View {
        
        Button( action: {
            document.save()
        },
                label:  {
            Label( "Save", systemImage: "arrow.down.doc.fill" )
                .labelStyle(.titleOnly)
        })
    }
    
}

//
// MARK: - Diagram extension -
//
extension PlantUMLContentView {
    
    
    var PlantUMLDiagramViewFit: some View {
        PlantUMLDiagramView( url: document.buildURL(), contentMode: .fit )
    }
    
    func ShareDiagramButton() -> some View {
        
        Button(action: {
            if let image = PlantUMLDiagramViewFit.asUIImage() {
                diagramImage = image
            }
        }) {
            ZStack {
                Image(systemName:"square.and.arrow.up")
                SwiftUIActivityViewController( uiImage: $diagramImage )
            }
            
        }
        
    }
    
    func ScaleToFitButton() -> some View {
        
        Toggle("fit image", isOn: $isScaleToFit)
            .toggleStyle(ScaleToFitToggleStyle())
        
    }
    
    func ToggleDiagramButton() -> some View {
        
        Button {
            if isEditorVisible {
                withAnimation {
                    // isPreviewVisible.toggle()
                    isEditorVisible.toggle()
                }
            }
        }
    label: {
        Label( "Toggle Preview", systemImage: "photo.fill" )
            .labelStyle(.iconOnly)
            .foregroundColor( isDiagramVisible ? .blue : .gray)
        
    }
    .accessibilityIdentifier("diagram")
    }
    
    
    
}


// MARK: - Preview -
struct ContentView_Previews: PreviewProvider {
    
    static var text = """

title test

actor myactor
participant participant1

myactor -> participant1


"""
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            Group {
                NavigationView {
                    PlantUMLContentView( document: PlantUMLDocumentProxy( document: .constant(PlantUMLDocument())))
                        .previewDevice(PreviewDevice(rawValue: "iPad mini (6th generation)"))
                        .environment(\.editMode, Binding.constant(EditMode.inactive))
                }
                .navigationViewStyle(.stack)
                .previewInterfaceOrientation(.landscapeRight)
                
                NavigationView {
                    PlantUMLContentView( document: PlantUMLDocumentProxy( document:  .constant(PlantUMLDocument())))
                        .previewDevice(PreviewDevice(rawValue: "iPad mini (6th generation)"))
                        .environment(\.editMode, Binding.constant(EditMode.inactive))
                }
                .navigationViewStyle(.stack)
                .previewInterfaceOrientation(.portrait)
                
            }
            .preferredColorScheme($0)
        }
    }
}

