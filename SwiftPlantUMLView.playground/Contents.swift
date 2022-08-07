//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport


class MyTextField : UITextField {
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        
        print( "canPerformAction \(action)")
        return super.canPerformAction(action, withSender: sender)
    }

}
class MyViewController : UIViewController {
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white

        let label = MyTextField()
        label.frame = CGRect(x: 150, y: 200, width: 200, height: 20)
        label.text = "Hello World!"
        label.textColor = .black

        view.addSubview(label)
        self.view = view
        
        print("loaded")
    }
    
}
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()
