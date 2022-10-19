//
//  LineEditorView.swift
//  LineEditor
//
//  Created by Bartolomeo Sorrentino on 17/10/22.
//

import SwiftUI
import Combine
import PlantUMLFramework

typealias Item = SyntaxStructure

protocol SharedActions {
   
    func addBelow()
    
    func addAbove()

    func cloneItem()
}


struct LineEditorView: UIViewControllerRepresentable  {
    
    @Environment(\.editMode) private var editMode
    
    typealias UIViewControllerType = Lines
    
    @Binding var items:Array<Item>
    
    func makeCoordinator() -> Coordinator {
        Coordinator( owner: self)
    }
    
    func makeUIViewController(context: Context) -> Lines {
        
        return context.coordinator.lines
    }
    
    func updateUIViewController(_ uiViewController: Lines, context: Context) {
        
        if let isEditing = editMode?.wrappedValue.isEditing {
            print( "editMode: \(isEditing)")
            uiViewController.isEditing = isEditing
        }
    }
    
}

// MARK: - Data Model
extension LineEditorView {
    
    class Line : UITableViewCell {
        
        let textField = UITextField()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            // contentView.isUserInteractionEnabled = false
            
            textField.keyboardType = .asciiCapable
            textField.autocapitalizationType = .none
            textField.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
            textField.returnKeyType = .done
            
            contentView.addSubview(textField)
            
            setupContraints()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setupContraints() {
            textField.translatesAutoresizingMaskIntoConstraints = false
            
            let constraints = [
                textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
                //textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
                textField.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -15.0),
                textField.heightAnchor.constraint(equalTo: contentView.heightAnchor)
            ]
            
            NSLayoutConstraint.activate(constraints)
        }
        
        
        
    }
    
    
    class Lines : UITableViewController {
        
        
        override func viewDidLoad() {
            tableView.register(LineEditorView.Line.self, forCellReuseIdentifier: "Cell")
            tableView.separatorStyle = .none
//            tableView.backgroundColor = UIColor.gray
            isEditing = false
        }
        
        func findFirstTextFieldResponder() -> UITextField? {
            
            return tableView.visibleCells
                .compactMap{ cell in
                    guard let cell = cell as? LineEditorView.Line else { return nil }
                    return cell.textField
                }
                .first { textField in
                    return textField.isFirstResponder
                }
        }
    }
    
}

// MARK: - Coordinator
extension LineEditorView {
    
    
    class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate  {
        
        let HEIGHT = 30.0
        
        var owner: LineEditorView
        
        let lines = Lines()
        
        private var customKeyboardMinHeight = 300.0
        private var keyboardRect:CGRect = .zero
        private var keyboardCancellable:AnyCancellable?
        private var showCustomKeyboard:Bool = false

        lazy var customKeybordView: UIView = {
            makeCustomKeyboardView()
        }()
        
        lazy var inputAccessoryView: UIView  = {
            makeInputAccesoryView()
        }()
        
        lazy var rightView: UIView = {
            makeContextMenuView()
        }()

        init(owner: LineEditorView ) {
            self.owner = owner
            super.init()
            
            lines.tableView.delegate = self
            lines.tableView.dataSource = self

            keyboardCancellable = keyboardRectPublisher.sink {  [weak self] rect in
                self?.keyboardRect = rect
            }

        }
        
        // MARK: - UITableViewDataSource
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            owner.items.count
        }
        
        private func setupTextField( _ textField: UITextField, withText text:String ) {
            if textField.delegate == nil {
                textField.delegate = self
            }
            
            if textField.rightView == nil {
                textField.rightView = rightView
                textField.rightViewMode = .whileEditing

            }
            if textField.inputAccessoryView == nil {
                textField.inputAccessoryView = inputAccessoryView
            }

            textField.text = text
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
            guard let line = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? LineEditorView.Line else {
                return UITableViewCell()
            }
            
            let text = owner.items[ indexPath.row ].rawValue
            
            setupTextField( line.textField, withText: text )
            
            
            return line
        }
        
        func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
        
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            switch( editingStyle ) {
            case .delete:
                print( "delete" )
                owner.items.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            case .insert:
                // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
                print( "insert" )
            case .none:
                print( "none" )
            @unknown default:
                print( "unknown editingStyle \(editingStyle)" )
            }
        }
        
        func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
            return true
        }
        
        func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
            
            owner.items.swapAt(sourceIndexPath.row, destinationIndexPath.row)
            
        }
        // MARK: - UITableViewDelegate
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            HEIGHT
        }
        
    }
    
}


// MARK: - Coordinator::SharedActions
extension LineEditorView.Coordinator : SharedActions {
    
    func addBelow() {
    }
    
    func addAbove() {
    }
    
    func cloneItem()  {
        
   }


}

// MARK: - Coordinator::Keyboard
extension LineEditorView.Coordinator {
    
    private var keyboardRectPublisher: AnyPublisher<CGRect, Never> {
        // 2.
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map {
                guard let rect = $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return CGRect.zero
                }
                
                self.customKeyboardMinHeight = max( self.customKeyboardMinHeight, rect.size.height)
                
                return rect
            }
        
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ in CGRect.zero }
            
        // 3.
        return Publishers.MergeMany(willShow, willHide).eraseToAnyPublisher()
                
    }
    
    // creation Input View
    private func makeCustomKeyboardView() -> UIView  {
        
        let keyboardView = PlantUMLKeyboardView(
            onHide: toggleCustomKeyobard,
            onPressSymbol: {_ in
                
            })
        
        let controller = UIHostingController( rootView: keyboardView )
        
        
        var customKeyboardRect = keyboardRect
        let MAGIC_NUMBER = 104.0 // 104.0 // magic number .. height of keyboard top bar
        
        customKeyboardRect.origin.y += MAGIC_NUMBER
        customKeyboardRect.size.height = max( self.customKeyboardMinHeight, customKeyboardRect.size.height) - MAGIC_NUMBER
        controller.view.frame = customKeyboardRect
        return controller.view
 
    }
    
    func toggleCustomKeyobard() {
        
        print( "toggleCustomKeyobard: \(self.showCustomKeyboard)" )
        
        guard let textField = lines.findFirstTextFieldResponder() else {
            return
        }
        
        showCustomKeyboard.toggle()
        
        if( showCustomKeyboard ) {
            textField.inputView = customKeybordView
            
            Task {

                let duration = UInt64(0.5 * 1_000_000_000)
                try? await Task.sleep(nanoseconds: duration )
                textField.reloadInputViews()
                textField.becomeFirstResponder()

            }
        }
        else {
            textField.inputView = nil
            textField.reloadInputViews()
        }
        

        
    }


}


// MARK: - Coordinator::UITextField
extension LineEditorView.Coordinator : UITextFieldDelegate {
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
    }
    

    private func makeInputAccesoryView() -> UIView {
        
        let bar = UIToolbar()
        
        let toggleKeyboardTitle = NSLocalizedString("PlantUML Keyboard", comment: "")
        let toggleKeyboardAction = UIAction(title: toggleKeyboardTitle) { [weak self] action in
            self?.toggleCustomKeyobard()
        }
        let toggleKeyboard = UIBarButtonItem(title: toggleKeyboardTitle,
                                             image: nil,
                                             primaryAction: toggleKeyboardAction )
        
        let addBelowTitle = NSLocalizedString("Add Below", comment: "")
        let addBelowAction = UIAction(title: addBelowTitle) { [weak self] action in
            //self?.owner.addBelow()
        }
        let addBelow = UIBarButtonItem(title: addBelowTitle,
                                       image: nil,
                                       primaryAction: addBelowAction )
        
        let addAboveTitle = NSLocalizedString("Add Above", comment: "")
        let addAboveAction = UIAction(title: addBelowTitle) { [weak self] action in
            //self?.owner.addAbove()
        }
        let addAbove = UIBarButtonItem(title: addAboveTitle,
                                       image: nil,
                                       primaryAction: addAboveAction)
        bar.items = [
            toggleKeyboard,
            addBelow,
            addAbove
        ]
        bar.sizeToFit()
        
        return bar
            
    }

}

// MARK: - Coordinator::ContextMenu
extension LineEditorView.Coordinator : UIContextMenuInteractionDelegate {
    
    private func makeContextMenuView() -> UIView {
        
        let image = UIImage(systemName: "contextualmenu.and.cursorarrow")
        
        //            let imageView = UIImageView( image: image )
        //
        //            let interaction = UIContextMenuInteraction(delegate: self)
        //            imageView.addInteraction(interaction)
        //            imageView.isUserInteractionEnabled = true
        //
        //            return imageView
        
        
        let button = UIButton()
        button.setImage( image, for: .normal )
        button.showsMenuAsPrimaryAction = true
        button.menu = makeContextMenu()
        
        return button
    }
    
    private func makeContextMenu() -> UIMenu {
        let addAboveAction =
        UIAction(title: NSLocalizedString("Add Above", comment: ""),
                 image: UIImage(systemName: "arrow.up.square")) { [weak self] action in
            self?.addAbove()
        }
        let addBelowAction =
        UIAction(title: NSLocalizedString("Add Below", comment: ""),
                 image: UIImage(systemName: "arrow.down.square")) { [weak self]  action in
            self?.addBelow()
        }
        let cloneRowAction =
        UIAction(title: NSLocalizedString("Clone", comment: ""),
                 image: UIImage(systemName: "plus.square.on.square"),
                 attributes: .destructive) { [weak self] action in
            self?.cloneItem()
        }
        return  UIMenu(title: "", children: [addAboveAction, addBelowAction, cloneRowAction])

    }

    // MARK: - UIContextMenuInteractionDelegate
            
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration?
    {
        return UIContextMenuConfiguration(  identifier: nil,
                                            previewProvider: nil ) { [weak self] _ in
            return  self?.makeContextMenu()
        }
    }

}

struct LineEditorView_Previews: PreviewProvider {
    static var previews: some View {
      
        LineEditorView( items: Binding.constant( [] ))
    }
}
