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

typealias PlantUMLLineEditorView = LineEditorView<SyntaxStructure,Symbol>

struct PlantUMLContentView: View {
    @Environment(\.editMode) private var editMode
    @Environment(\.openURL) private var openURL
    @State var keyboardTab: String = "general"
    
    @Binding var document: PlantUMLDocument
    @StateObject var diagram: PlantUMLDocumentProxy
    
    @State private var isEditorVisible  = true
    //@State private var isPreviewVisible = false
    private var isDiagramVisible:Bool { !isEditorVisible}
    
    @State private var isScaleToFit     = true
    @State private var fontSize         = CGFloat(12)
    @State var showLine:Bool            = false
    
    @State var diagramImage:UIImage?
    
    var PlantUMLDiagramViewFit: some View {
        PlantUMLDiagramView( url: diagram.buildURL(), contentMode: .fit )
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                if( isEditorVisible ) {
                    PlantUMLLineEditorView( items: $diagram.items,
                                            fontSize: $fontSize,
                                            showLine: $showLine) { onHide, onPressSymbol in
                        PlantUMLKeyboardView( selectedTab: $keyboardTab,
                                              onHide: onHide,
                                              onPressSymbol: onPressSymbol)
                    }
                    .onChange(of: diagram.items ) { _ in
                        diagram.updateRequest.send()
                    }
                    .onReceive(diagram.updateRequest.publisher) { _ in
                        saveToDocument()
                    }
                }
//                Divider().background(Color.blue).padding()
                
                if isDiagramVisible {
                    if isScaleToFit {
                        PlantUMLDiagramViewFit
                            .frame( width: geometry.size.width, height: geometry.size.height )
                    }
                    else {
                        ScrollView([.horizontal, .vertical], showsIndicators: true) {
                            PlantUMLDiagramView( url: diagram.buildURL(), contentMode: .fill )
                                .frame( minWidth: geometry.size.width)
                        }
                        .frame( minWidth: geometry.size.width, minHeight: geometry.size.height )
                    }
                }
                    
            }
            .onRotate(perform: { orientation in
                if  (orientation.isPortrait && isDiagramVisible) ||
                    (orientation.isLandscape && isEditorVisible)
                {
                    isEditorVisible.toggle()
                }
            })
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if isEditorVisible {
                        HStack {
                            // SaveButton()
                            EditButton()
                            Divider().background(Color.blue).padding(10)
                            fontSizeView()
                            toggleLineNumberView()
                        }
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    HStack( spacing: 0 ) {
                        ToggleEditorButton()
                        TogglePreviewButton()
                        if isDiagramVisible {
                            ScaleToFitButton()
                            ShareDiagramButton()
                        }
                    }
                }
                
            }
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
            Divider().background(Color.blue)
            Button( action: { fontSize -= 1} ) {
                Image( systemName: "textformat.size.smaller")
            }
            .padding( EdgeInsets(top:0, leading: 5,bottom: 0, trailing: 0))
        }
//        .overlay {
//            RoundedRectangle(cornerRadius: 16)
//                .stroke(.blue, lineWidth: 1)
//        }
        .padding()
    }
        
    func SaveButton() -> some View {
        
        Button( action: saveToDocument ) {
            Label( "Save", systemImage: "arrow.down.doc.fill" )
                .labelStyle(.titleOnly)
        }
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

    func TogglePreviewButton() -> some View {
        
        Button {
            if isEditorVisible {
                withAnimation {
                    // isPreviewVisible.toggle()
                    isEditorVisible.toggle()
                }
            }
        }
        label: {
//            Label( "Toggle Preview", systemImage: "rectangle.righthalf.inset.filled" )
            Label( "Toggle Preview", systemImage: "photo.fill" )
            
                .labelStyle(.iconOnly)
                .foregroundColor( isDiagramVisible ? .blue : .gray)
                
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
//            Label( "Toggle Editor", systemImage: "rectangle.lefthalf.inset.filled" )
            Label( "Toggle Editor", systemImage: "doc.plaintext.fill" )
                .labelStyle(.iconOnly)
                .foregroundColor( isEditorVisible ? .blue : .gray)

        }
    }

 
}

// MARK: ACTIONS
extension PlantUMLContentView {
    
    internal func saveToDocument() {
        print( "save document")
        document.text = diagram.description
    }
        
}

struct ContentView_Previews: PreviewProvider {
    
    static var text = """

title test

actor myactor
participant participant1

myactor -> participant1


"""
    static var previews: some View {
        
        Group {
            NavigationView {
                PlantUMLContentView(document: .constant(PlantUMLDocument()),
                                    diagram: PlantUMLDocumentProxy( text: text))
                    .previewDevice(PreviewDevice(rawValue: "iPad mini (6th generation)"))
                    .environment(\.editMode, Binding.constant(EditMode.inactive))
            }
            .navigationViewStyle(.stack)
            .previewInterfaceOrientation(.landscapeRight)

            NavigationView {
                PlantUMLContentView(document: .constant(PlantUMLDocument()),
                                    diagram: PlantUMLDocumentProxy( text: text))
                    .previewDevice(PreviewDevice(rawValue: "iPad mini (6th generation)"))
                    .environment(\.editMode, Binding.constant(EditMode.inactive))
            }
            .navigationViewStyle(.stack)
            .previewInterfaceOrientation(.portrait)
        }
    }
}

