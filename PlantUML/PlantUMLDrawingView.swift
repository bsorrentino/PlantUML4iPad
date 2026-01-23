//
//  DrawingView.swift
//  PlantUMLApp
//
//  Created by bsorrentino on 28/12/23.
//

import SwiftUI
import PencilKit
import AIAgent
import PhotosUI
import UniformTypeIdentifiers
import UIKit
import DrawOnImage

#Preview( "PlantUMLDrawingView") {
    
    let doc = PlantUMLObservableDocument(document:.constant(PlantUMLDocument()), fileName:"Untitled")
    
    NavigationStack {
#if USE_OBSERVABLE
        PlantUMLDrawingView(
            service: AIObservableService(),
            document: .constant(doc)
        ).environmentObject(NetworkObservableService())
#else
        PlantUMLDrawingView(
            service: OpenAIObservableService(),
            document: doc
        ).environmentObject(NetworkObservableService())
#endif

    }
}

struct PlantUMLDrawingView: View {
    @Environment( \.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @ObservedObject var service:AIObservableService
    #if USE_OBSERVABLE
    @Binding var document: PlantUMLObservableDocument
    #else
    @ObservedObject var document: PlantUMLObservableDocument
    #endif
    @EnvironmentObject var networkService: NetworkObservableService
    @State var isScrollEnabled = false
    @State var isUseDrawingTool = false
    @State var processing = false
    @State var processingLabel: String = "👀 Processing ..."
    @State private var processImageTask:Task<(),Never>? = nil
    
    // Image importing state
    //@State private var importedImage: UIImage? = nil
    @State private var showPhotoPicker = false
    @State private var showCameraPicker = false
    @State private var showFilesPicker = false
    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var resultImage: UIImage? = nil
    @State private var requestImage = false
    
    var body: some View {
        
        ActivityView(isShowing: processing, label: processingLabel )  {
            
            DrawingView(document: document,
                        isUsePickerTool: isUseDrawingTool,
                        isScrollEnabled: isScrollEnabled,
                        requestImage: requestImage,
                        resultImage: $resultImage)
            .onChange(of: requestImage, initial: false) { oldValue, newValue in
                if newValue {
                    processImage()
                    requestImage = false
                }
            }
            .font(.system(size: 35))
            //.navigationBarTitleDisplayMode(.inline)
            .foregroundColor(Color.purple)
            .navigationBarTitle( "\(document.fileName)   -   📝 Draw Diagram", displayMode: .inline )
            .navigationBarItems(trailing:
                HStack(spacing: 10) {
                // Import menu
                Menu {
                    Button(action: { showPhotoPicker = true }) {
                        Label("Photos", systemImage: "photo")
                    }
                    Button(action: { pasteFromClipboard() }) {
                        Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                    }
                    Button(action: { showCameraPicker = true }) {
                        Label("Camera", systemImage: "camera")
                    }
                    Button(action: { showFilesPicker = true }) {
                        Label("Files", systemImage: "folder")
                    }
                    if document.drawingBackgroundImage != nil {
                        Button(role: .destructive, action: { document.drawingBackgroundImage = nil }) {
                            Label("Clear Image", systemImage: "trash")
                        }
                    }
                } label: {
                    Label("Import", systemImage: "photo.badge.plus")
                        .foregroundColor(Color.orange)
                }
                .accessibilityIdentifier("drawing_import")
                
                Divider()
                
                Button(action: {
                    isScrollEnabled.toggle()
                }) {
                    Label( "tools", systemImage:  isScrollEnabled ? "lock.open.fill" : "lock.fill" )
                        .foregroundColor(Color.orange)
                        .labelStyle(.iconOnly)
                }
                .accessibilityIdentifier("drawing_lock")
                Button(action: {
                    isUseDrawingTool.toggle()
                }) {
                    Label( "tools", systemImage: "rectangle.and.pencil.and.ellipsis")
                        .foregroundColor(Color.orange)
                        .labelStyle(.titleOnly)
                }
                .accessibilityIdentifier("drawing_tools")
                
                Divider()
                
                Button( action: {
                    //processImage()
                    requestImage = true
                }, label: {
                    Label( "process", systemImage: "eye")
                        .foregroundColor(Color.orange)
                        .labelStyle(.titleOnly)
                        .networkEnabledStyle(networkService)
                    
                })
                .accessibilityIdentifier("drawing_process")
                .networkEnabled(networkService)
            })
        }
        .onCancel {
            processImageTask?.cancel()
        }
        .onDisappear( perform: updateDiagram )
        // Photos picker (Photo Library)
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoPickerItem, matching: .images)
        .onChange(of: photoPickerItem ) { oldItem, newItem in
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    document.drawingBackgroundImage = uiImage
                }
            }
        }
        // Camera picker
        .sheet(isPresented: $showCameraPicker) {
            CameraPicker(image: $document.drawingBackgroundImage)
                .ignoresSafeArea()
        }
        // Files picker
        .sheet(isPresented: $showFilesPicker) {
            DocumentImagePicker(image: $document.drawingBackgroundImage)
        }
    }
    
    private func saveImageToPhotos() {
        // saving to album
        guard let resultImage else {
            return
        }
        UIImageWriteToSavedPhotosAlbum(resultImage, nil, nil, nil)
        
    }
    
    private func updateDiagram() {
        // document.drawingData = canvas.drawing.dataRepresentation()
    }
    
    private func pasteFromClipboard() {
        let pb = UIPasteboard.general
        if let img = pb.image {
            document.drawingBackgroundImage = img
        } else if let data = pb.data(forPasteboardType: UTType.png.identifier),
                  let img = UIImage(data: data) {
            document.drawingBackgroundImage = img
        }
    }
    
}


///
//MARK: - Vision extension
///
extension PlantUMLDrawingView : AgentExecutorDelegate {
    
    func progress(_ message: String) {
        processingLabel = message
    }
    
    fileprivate func saveData( _ data: Data,
                               toFile fileName: String,
                               inDirectory directory: FileManager.SearchPathDirectory ) {
        do {
            let dir = try FileManager.default.url(for: directory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true)
            let fileURL = dir.appendingPathComponent(fileName)
            print( "fileURL\n\(fileURL)")
            try data.write(to: fileURL)
        }
        catch {
            print( "error saving file \(error.localizedDescription)" )
        }
    }
    
    func processImage() {
        guard let resultImage else {
            return
        }
        
        updateDiagram()
        
        // getting image from Canvas
        
        let backgroundColor:UIColor = (colorScheme == .dark ) ? .black : .white
        let image = resultImage.withBackgroundColor(backgroundColor)
        
        if let imageData = image.pngData() {
            
            if SAVE_DRAWING_IMAGE {
                saveData(imageData,
                         toFile: "image.png",
                         inDirectory: .picturesDirectory)
            }
            
            processing.toggle()
            isUseDrawingTool = false
            service.status = .Ready
            
            processImageTask = Task {
                
                defer { dismiss() }
                
                if let content = await service.processImageWithAgents( imageData: imageData, delegate: self ) {
                    document.text = content
                }
                
            }
            
        }
    }
    
}

// MARK: - UIKit bridges for Camera and Files

private struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let img = info[.originalImage] as? UIImage {
                parent.image = img
            }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

private struct DocumentImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.png, .jpeg, .heic, .image]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentImagePicker
        init(_ parent: DocumentImagePicker) { self.parent = parent }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
                    parent.image = img
                }
            } else if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
                parent.image = img
            }
        }
    }
}
