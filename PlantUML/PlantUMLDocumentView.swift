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
import CodeViewer
import AppSecureStorage
import PencilKit

//
// [Managing Focus in SwiftUI List Views](https://peterfriese.dev/posts/swiftui-list-focus/)
//
//  enum Focusable: Hashable {
//      case none
//      case row(id: String)
//  }


struct PlantUMLDocumentView: View {
    typealias PlantUMLEditorView = CodeViewer
    
    @Environment(\.scenePhase) var scene
    @Environment(\.interfaceOrientation) var interfaceOrientation: InterfaceOrientationHolder
    @Environment(\.openURL) private var openURL
    
    @AppStorage("lightTheme") var lightTheme:String = CodeWebView.Theme.chrome.rawValue
    @AppStorage("darkTheme") var darkTheme:String = CodeWebView.Theme.monokai.rawValue
    @AppStorage("fontSize") var fontSize:Int = 15
    
    @StateObject var document: PlantUMLObservableDocument
    @StateObject private var openAIService = OpenAIObservableService()
    
    @State var isOpenAIVisible  = false
    
    @State var keyboardTab: String  = "general"
    @State private var showLine:Bool = true
    @State private var saving = false
    
    @State private var editorViewId  = 1
    
    @State private var canvas = PKCanvasView()
    
    var body: some View {
        
        VStack {
            GeometryReader { geometry in
                
                
                VStack {
                    PlantUMLEditorView( content: $document.text,
                                        darkTheme: CodeWebView.Theme(rawValue: darkTheme)!,
                                        lightTheme: CodeWebView.Theme(rawValue: lightTheme)!,
                                        isReadOnly: false,
                                        fontSize: CGFloat(fontSize),
                                        showGutter: showLine
                    )
                    .id( editorViewId )
                    .if( isRunningTests ) { /// this need for catching current editor data from UI test
                        $0.overlay(alignment: .bottom) {
                            Text( document.text )
                                .frame( width: 0, height: 0)
                                .opacity(0)
                                .accessibilityIdentifier("editor-text")
                        }
                    }
                }
                
                
            }
            if isOpenAIVisible /* && interfaceOrientation.value.isPortrait */ {
                OpenAIView( service: openAIService,
                            document: document,
                            drawingView:  { DiagramDrawingView } )
                .frame( height: 200 )
                .onChange(of: openAIService.status ) { newStatus in
                    if( .Ready == newStatus ) {
                        // Force rendering editor view
                        //                            print( "FORCE RENDERING OF EDITOR VIEW")
                        editorViewId += 1
                    }
                }
                
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
            //            if  (orientation.isPortrait && isDiagramVisible) ||
            //                    (orientation.isLandscape && isEditorVisible)
            //            {
            //                isEditorVisible.toggle()
            //            }
        })
//        .navigationBarTitle(Text( "📝 Diagram Editor" ), displayMode: .inline)
        
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) { }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                HStack( spacing: 0 ) {
                    SavingStateView( saving: saving )
                    
                    HStack(alignment: .center, spacing: 5) {
                        ToggleOpenAIButton
                        Divider().background(Color.blue)
                    }
                    .frame(height:20)

                    HStack {
                        updateEditorFontSizeView()
                        toggleEditorLineNumberView()
                        shareDiagramTextView()
                    }
                    
                    ToggleDiagramButton()
                }
            }
        }
    }
}

//
// MARK: - Drawing extension -
//
extension PlantUMLDocumentView {
    
    var DiagramDrawingView: some View {
        
        NavigationStack {
            PlantUMLDrawingView( canvas: $canvas,
                                 service: openAIService,
                                 document: document )
            
        }
        
    }
}

//
// MARK: - Editor extension -
//
extension PlantUMLDocumentView {
    
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
                        PlantUMLDocumentView.SavedStateView( visible: $visible )
                    }
                }
            }
            .foregroundColor(Color.secondary)
            .frame( maxWidth: 100 )
        }
        
    }
    
    func toggleEditorLineNumberView() -> some View {
        Button( action: { showLine.toggle() } ) {
            Image( systemName: "list.number")
        }
        
    }
    
    func updateEditorFontSizeView() -> some View {
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
    
    func shareDiagramTextView() -> some View {
        ShareLink( item: document.text, 
                   subject: Text("PlantUML Script"))
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
extension PlantUMLDocumentView {
    
    func ToggleDiagramButton() -> some View {
        
        NavigationLink(  destination: {
            PlantUMLDiagramView( url: document.buildURL())
                .toolbarRole(.navigationStack)
        }) {
            Label( "Preview >", systemImage: "photo.fill" )
                .labelStyle(.titleOnly)
                .foregroundColor( .blue )
        }
        .accessibilityIdentifier("diagram_preview")
        .padding(.leading, 15)
        
    }
    
}


// MARK: - Preview -
#Preview {
    
    let preview_text = """

    title test

    actor myactor
    participant participant1

    myactor -> participant1


    """

    return NavigationStack {
        PlantUMLDocumentView( document: PlantUMLObservableDocument(
            document: .constant(PlantUMLDocument( text: preview_text)), fileName:"Untitled" ))
        .navigationViewStyle(.stack)
    }
    
    
}

