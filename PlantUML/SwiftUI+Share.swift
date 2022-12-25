//
//  SwiftUI+Share.swift
//  PlantUML4iPad
//
//  Created by Bartolomeo Sorrentino on 22/12/22.
//
// inspired by https://stackoverflow.com/a/56828100/521197

import SwiftUI


struct SwiftUIActivityViewController : UIViewControllerRepresentable {
    
    class ActivityViewController : UIViewController {

        @objc func shareImage( _ uiImage: UIImage? ) {
            guard let uiImage else {
                return
            }
            let vc = UIActivityViewController(activityItems: [uiImage], applicationActivities: [])
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
struct SwiftUIActivityViewController_Previews: PreviewProvider {
    
    struct ContentView_Previews : View {
        
        @State var uiImage:UIImage?
        
        // @ref https://stackoverflow.com/a/65095862/521197
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
    
    static var previews: some View {
        ContentView_Previews()
    }
}
