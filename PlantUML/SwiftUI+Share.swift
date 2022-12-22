//
//  SwiftUI+Share.swift
//  PlantUML4iPad
//
//  Created by Bartolomeo Sorrentino on 22/12/22.
//
// inspired by https://stackoverflow.com/a/56828100/521197

import SwiftUI


class ActivityViewController : UIViewController {

    @objc func shareImage( _ uiImage: UIImage ) {
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


struct SwiftUIActivityViewController : UIViewControllerRepresentable {

    let activityViewController = ActivityViewController()

    func makeUIViewController(context: Context) -> ActivityViewController {
        activityViewController
    }
    
    func updateUIViewController(_ uiViewController: ActivityViewController, context: Context) {
        //
    }

    func shareImage(uiImage: UIImage) {
        activityViewController.shareImage( uiImage )
    }
}

// MARK: - Preview
struct SwiftUIActivityViewController_Previews: PreviewProvider {
    
    struct ContentView_Previews : View {
        
        let activityViewController = SwiftUIActivityViewController()
        
        @State var uiImage = UIImage(named: "uml")
        
        var body: some View {
            VStack {
                Button(action: {
                    self.activityViewController.shareImage(uiImage: self.uiImage!)
                }) {
                    ZStack {
                        Image(systemName:"square.and.arrow.up")
                            .renderingMode(.original)
                            .font(Font.title.weight(.regular))
                        activityViewController
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
