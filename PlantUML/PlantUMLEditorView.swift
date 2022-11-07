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

// [Managing Focus in SwiftUI List Views](https://peterfriese.dev/posts/swiftui-list-focus/)
//enum Focusable: Hashable {
//  case none
//  case row(id: String)
//}

typealias PlantUMLLineEditorView = LineEditorView<SyntaxStructure,PlantUMLKeyboardView>

struct PlantUMLEditorView: View {
    @Environment(\.editMode) private var editMode
    @Environment(\.openURL) private var openURL
    
    @EnvironmentObject private var diagram: PlantUMLDiagramObject
    
    @Binding var document: PlantUMLDocument
    
    @State private var isEditorVisible  = true
    @State private var isPreviewVisible = true
    @State private var isScaleToFit     = true
    @State private var fontSize         = CGFloat(15)

    var body: some View {
        GeometryReader { geometry in
            HStack {
                if( isEditorVisible ) {
                    PlantUMLLineEditorView( items: $diagram.items,
                                            fontSize: $fontSize )
                        
                }
                Divider().background(Color.blue).padding()
                if isPreviewVisible {
                    if isScaleToFit {
                        PlantUMLDiagramView( url: diagram.buildURL() )
                    }
                    else {
                        PlantUMLScrollableDiagramView( url: diagram.buildURL(), size: geometry.size )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    EditButton()
                    SaveButton()
                    fontSizeView()
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    ScaleToFitButton()
                    HStack( spacing: 0 ) {
                        ToggleEditorButton()
                        TogglePreviewButton()
                    }
                }
                
            }
        }
    }
    
    func fontSizeView() -> some View {
        HStack( spacing: 0 ) {
            Button( action: { fontSize += 1 } ) {
                Image( systemName: "textformat.size.larger")
            }
            Divider().background(Color.blue)
            Button( action: { fontSize -= 1} ) {
                Image( systemName: "textformat.size.smaller")
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.blue, lineWidth: 1)
        }
        .padding()
    }
        
    func SaveButton() -> some View {
        
        Button( action: saveToDocument ) {
            Label( "Save", systemImage: "arrow.down.doc.fill" )
                .labelStyle(.titleOnly)
        }
    }

    func ScaleToFitButton() -> some View {
        
        Toggle("fit image", isOn: $isScaleToFit)
    }

    func TogglePreviewButton() -> some View {
        
        Button {
            withAnimation {
                isPreviewVisible.toggle()
                if !isPreviewVisible && !isEditorVisible  {
                    isEditorVisible.toggle()
                }
            }
        }
        label: {
            Label( "Toggle Preview", systemImage: "rectangle.righthalf.inset.filled" )
                .labelStyle(.iconOnly)
                .foregroundColor( isPreviewVisible ? .blue : .gray)
                
        }
    }

    func ToggleEditorButton() -> some View {
        
        Button {
            withAnimation {
                isEditorVisible.toggle()
                if !isEditorVisible && !isPreviewVisible  {
                    isPreviewVisible.toggle()
                }

            }
        }
        label: {
            Label( "Toggle Editor", systemImage: "rectangle.lefthalf.inset.filled" )
                .labelStyle(.iconOnly)
                .foregroundColor( isEditorVisible ? .blue : .gray)

        }
    }

 
}

// MARK: ACTIONS
extension PlantUMLEditorView {
    
    internal func saveToDocument() {
        document.text = diagram.description
    }
        
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PlantUMLEditorView(document: .constant(PlantUMLDocument()))
                .previewDevice(PreviewDevice(rawValue: "iPad mini (6th generation)"))
                .environment(\.editMode, Binding.constant(EditMode.inactive))
                
                .environmentObject( PlantUMLDiagramObject( text:
"""

title test

"""))
        }
        .navigationViewStyle(.stack)
        .previewInterfaceOrientation(.landscapeRight)
    }
}
