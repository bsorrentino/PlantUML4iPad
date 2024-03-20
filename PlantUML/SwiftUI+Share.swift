//
//  SwiftUI+Share.swift
//  PlantUML4iPad
//
//  Created by Bartolomeo Sorrentino on 22/12/22.
//
// inspired by [SwiftUI exporting or sharing files](https://stackoverflow.com/a/56828100/521197)

import SwiftUI
import LinkPresentation

//@available(*, deprecated, message: "Don't use this anymore. Use ShareLink view instead!")
struct SwiftUIActivityViewController : UIViewControllerRepresentable {
    
    class ActivitySource : NSObject,  UIActivityItemSource {
        
        var uiImage: UIImage
        var placeholder: UIImage
        
        init(_ uiImage: UIImage, placeholder: UIImage ) {
            self.uiImage = uiImage
            self.placeholder = placeholder
        }
        
        func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
            placeholder
        }
        
        func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
            uiImage
        }
        
        func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
            "Diagram Image"
        }
        
        ///
        /// [Sharing data with UIActivityViewController - tips & tricks](https://nemecek.be/blog/189/wip-sharing-data-with-uiactivityviewcontroller-tips-tricks)
        /// 
        func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
             let metadata = LPLinkMetadata()

             metadata.iconProvider = NSItemProvider(object: placeholder)
             metadata.title = "plantum diagram"

             return metadata
         }
    }
    
    class ActivityViewController : UIViewController {

        @objc func shareImage( _ uiImage: UIImage? ) {
            guard let uiImage else {
                print( "sharing image is null!")
                return
            }
            guard let placheholder = UIImage(named: "uml") else {
                print( "placeholder image is null!")
                return
            }

            let itemSource = ActivitySource(uiImage, placeholder: placheholder)
            
            let vc = UIActivityViewController(activityItems: [itemSource],
                                              applicationActivities: [])
            vc.excludedActivityTypes =  [
                UIActivity.ActivityType.postToWeibo,
                UIActivity.ActivityType.assignToContact,
                UIActivity.ActivityType.addToReadingList,
                UIActivity.ActivityType.postToVimeo,
                UIActivity.ActivityType.postToTencentWeibo
            ]
            present(vc,
                    animated: true,
                    completion: nil)
            vc.popoverPresentationController?.sourceView = self.view
        }
    }

    @Binding var uiImage: UIImage?

    func makeUIViewController(context: Context) -> ActivityViewController {
        ActivityViewController()
    }
    
    func updateUIViewController(_ uiViewController: ActivityViewController, context: Context) {
        uiViewController.shareImage( uiImage )
    }

}

// MARK: - Preview

#Preview {

    struct ContentView_Previews : View {
        
        @State var uiImage:UIImage?
        
        // [SwiftUI: Forcing an Update](https://stackoverflow.com/a/65095862/521197)
        @State var id = 1
        
        var body: some View {
            VStack {
                Button(action: {
                    id += 1
                    uiImage = UIImage(named: "uml")
                }) {
                    ZStack {
                        Image(systemName:"square.and.arrow.up")
                            .renderingMode(.original)
                            .font(Font.title.weight(.regular))
                        SwiftUIActivityViewController( uiImage: $uiImage ).id(id)
                    }
                }
                .frame(width: 60, height: 60)
                Spacer()
    //                Image(uiImage: uiImage!)
            }
        }
    }

    return ContentView_Previews()
}

