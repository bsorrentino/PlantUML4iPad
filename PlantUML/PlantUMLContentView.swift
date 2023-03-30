//
//  ContentView.swift
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
    typealias PlantUMLLineEditorView = StandardLineEditorView<SyntaxStructure,Symbol>

    class ViewState : ObservableObject, Identifiable {
        
        @Published var isOpenAIVisible  = false
        @Published var isEditorVisible  = true
        @Published var id = 1

        var isDiagramVisible:Bool { !isEditorVisible }

        func forceUpdate() {
            id += 1
        }

    }

    @Environment(\.editMode) private var editMode
    @Environment(\.openURL) private var openURL
    @State var keyboardTab: String = "general"
    
    @StateObject var document: PlantUMLDocumentProxy
    
    @StateObject var viewState = ViewState()
        
    @State private var isScaleToFit     = true
    @State private var fontSize         = CGFloat(12)
    @State private var showLine:Bool    = false
    
    @State private var diagramImage:UIImage?
    
    @State private var saving = false
    
    @State private var openAIResult:String = ""
    
    
    var PlantUMLDiagramViewFit: some View {
        PlantUMLDiagramView( url: document.buildURL(), contentMode: .fit )
    }
    
    
    var EditorView_Fragment: some View {
        
        PlantUMLLineEditorView( items: $document.items,
                                fontSize: $fontSize,
                                showLine: $showLine) { onHide, onPressSymbol in
            PlantUMLKeyboardView( selectedTab: $keyboardTab,
                                  onHide: onHide,
                                  onPressSymbol: onPressSymbol)
        }
                                .onChange(of: document.items ) { _ in
                                    saving = true
                                    document.updateRequest.send()
                                }
    }
    
    var OpenAIView_Fragment: some View {
        
        OpenAIView( result: $openAIResult, input: document.text,
                    onApply: {
            saving = true
            document.updateRequest.send()
        },
                    onUndo: {
            document.reset()
            viewState.forceUpdate()
        })
        .onChange(of: openAIResult ) { result in
            document.text = result
            viewState.forceUpdate()
        }
        
    }
    
    func DiagramView_Fragment( size: CGSize ) -> some View {
        
        Group {
            if isScaleToFit {
                PlantUMLDiagramViewFit
                    .frame( width: size.width, height: size.height  )
            }
            else {
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    PlantUMLDiagramView( url: document.buildURL(), contentMode: .fill )
                        .frame( minWidth: size.width)
                }
                .frame( minWidth: size.width, minHeight: size.height )
            }
        }
        
    }
    
    var body: some View {
        
        VStack {
            GeometryReader { geometry in
                if( viewState.isEditorVisible ) {
                    EditorView_Fragment
                }
                if viewState.isDiagramVisible {
                    DiagramView_Fragment( size: geometry.size )
                }
            }
            if viewState.isOpenAIVisible {
                Divider()
                OpenAIView_Fragment
            }
        }
        .id( viewState.id )
        .onReceive(document.updateRequest.publisher) { _ in
            withAnimation(.easeInOut(duration: 1.0)) {
                document.save()
                saving = false
            }
        }
        //.navigationBarTitleDisplayMode(.inline)
        .onRotate(perform: { orientation in
            if  (orientation.isPortrait && viewState.isDiagramVisible) ||
                    (orientation.isLandscape && viewState.isEditorVisible)
            {
                viewState.isEditorVisible.toggle()
            }
        })
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                //                    if isEditorVisible {
                //                        HStack {
                //                            EditButton()
                //                            fontSizeView()
                //                            toggleLineNumberView()
                //                        }
                //                    }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                HStack( spacing: 0 ) {
                    SavingStateView( saving: saving )
                    
                    ToggleEditorButton()
                    if viewState.isEditorVisible {
                        HStack {
                            EditButton()
                            fontSizeView()
                            toggleLineNumberView()
                            ToggleOpenAIButton()
                        }
                    }
                    
                    ToggleDiagramButton()
                    if viewState.isDiagramVisible {
                        ScaleToFitButton()
                        ShareDiagramButton()
                    }
                }
            }
        }
    }
}

//
// MARK: - Editor actions -
//
extension PlantUMLContentView {
    
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
            .padding( EdgeInsets(top:0, leading: 5,bottom: 0, trailing: 0))
            Divider().background(Color.blue).frame(height:20)
            Button( action: { fontSize -= 1} ) {
                Image( systemName: "textformat.size.smaller")
            }
            .padding( EdgeInsets(top:0, leading: 5,bottom: 0, trailing: 0))
        }
        //        .overlay {
        //            RoundedRectangle(cornerRadius: 16)
        //                .stroke(.blue, lineWidth: 1)
        //        }
        //.padding()
    }
    
    func ToggleEditorButton() -> some View {
        
        Button {
            if !viewState.isEditorVisible {
                withAnimation {
                    diagramImage = nil // avoid popup of share image UIActivityViewController
                    viewState.isEditorVisible.toggle()
                }
            }
        }
        label: {
            Label( "Toggle Editor", systemImage: "doc.plaintext.fill" )
                .labelStyle(.iconOnly)
                .foregroundColor( viewState.isEditorVisible ? .blue : .gray)
        
        }
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
// MARK: - Diagram actions
//
extension PlantUMLContentView {
    
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
            if viewState.isEditorVisible {
                withAnimation {
                    // isPreviewVisible.toggle()
                    viewState.isEditorVisible.toggle()
                }
            }
        }
        label: {
            Label( "Toggle Preview", systemImage: "photo.fill" )
                .labelStyle(.iconOnly)
                .foregroundColor( viewState.isDiagramVisible ? .blue : .gray)
        }
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

