//
//  LineEditorView.swift
//  LineEditor
//
//  Created by Bartolomeo Sorrentino on 17/10/22.
//

import SwiftUI
import Combine

protocol KeyboardSymbol {
    
    var value: String {get}
    
    var additionalValues: [String]? {get}
}

public struct LineEditorView<Element: RawRepresentable<String>>: UIViewControllerRepresentable {
    
    @Environment(\.editMode) private var editMode
    
    public typealias UIViewControllerType = Lines
    
    @Binding var items:Array<Element>
    
    public init( items: Binding<Array<Element>> ) {
        self._items = items
    }
    public func makeCoordinator() -> Coordinator {
        Coordinator( owner: self)
    }
    
    public func makeUIViewController(context: Context) -> Lines {
        
        return context.coordinator.lines
    }
    
    public func updateUIViewController(_ uiViewController: Lines, context: Context) {
        
        if let isEditing = editMode?.wrappedValue.isEditing {
            print( "editMode: \(isEditing)")
            uiViewController.isEditing = isEditing
        }
        
        items.forEach { print( $0 ) }
    }

}

// MARK: - Data Model
extension LineEditorView {
    
    class TextField : UITextField {
        var indexPath: IndexPath?
        
    }
    
    public class Line : UITableViewCell {
        
        let textField = TextField()
        
        private var tableView:UITableView {
            guard let tableView = self.superview as? UITableView else {
                fatalError("superview is not a UITableView")
            }
            return tableView
        }
        
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
    
    
    public class Lines : UITableViewController {
        
        var timerCancellable: Cancellable?
        
        public override func viewDidLoad() {
            tableView.register(LineEditorView.Line.self, forCellReuseIdentifier: "Cell")
            tableView.separatorStyle = .none
//            tableView.backgroundColor = UIColor.gray
            isEditing = false
        }
        
        func findFirstTextFieldResponder() -> LineEditorView.TextField? {
            
            return tableView.visibleCells
                .compactMap { cell in
                    guard let cell = cell as? LineEditorView.Line else { return nil }
                    return cell.textField
                }
                .first { textField in
                    return textField.isFirstResponder
                }
        }
        
        private func becomeFirstResponder( at indexPath: IndexPath ) -> Bool {
            var done = false
            if let cell = tableView.cellForRow(at: indexPath) as? LineEditorView.Line {
                done  = cell.textField.becomeFirstResponder()
            }
            return done
        }
        
        func becomeFirstResponder( at indexPath: IndexPath, withRetries retries: Int ) {
            
            timerCancellable?.cancel()
            
            if !becomeFirstResponder(at: indexPath) {
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: true);
                
                timerCancellable = Timer.publish(every: 0.5, on: .main, in: .default)
                    .autoconnect()
                    .prefix( max(retries,1) )
                    .sink { [weak self] _ in
                        
                        if let self = self, self.becomeFirstResponder( at: indexPath)  {
                            print( "becomeFirsResponder: done!")
                            self.timerCancellable?.cancel()
                        }

                    }

            }
                
        }
    }
    
}

// MARK: - Coordinator
extension LineEditorView {
    
    
    public class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate  {
        
        private let ROW_HEIGHT = 30.0
        private let CUSTOM_KEYBOARD_MIN_HEIGHT = 402.0

        let owner: LineEditorView
        
        let lines = Lines()
        
        private var keyboardRect:CGRect = .zero
        private var keyboardCancellable:AnyCancellable?
        private var showCustomKeyboard:Bool = false
        
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
                print( "keyboardRect: \(rect)")
                self?.keyboardRect = rect
            }

        }
        
        // MARK: - UITableViewDataSource
        
        public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            owner.items.count
        }
        
        private func disabledCell() -> UITableViewCell {
            let cell =  UITableViewCell()
            cell.selectionStyle = .none
            cell.isUserInteractionEnabled = false
            return cell
        }
        
        public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
            guard let line = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? LineEditorView.Line else {
                return disabledCell()
            }
            
            setupTextField( line.textField,
                            at: indexPath,
                            withText: owner.items[ indexPath.row ].rawValue)
            
            print( "cellForRowAt: \(indexPath.row) - \(owner.items[ indexPath.row ].rawValue)")
            
            return line
        }
        
        public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            true
        }
        
        public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
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
        
        public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
            true
        }
        
        public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
            owner.items.swapAt(sourceIndexPath.row, destinationIndexPath.row)
        }
        
        // MARK: - UITableViewDelegate
        
        
        public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            ROW_HEIGHT
        }
     
        // MARK: - UITextFieldDelegate
        
        public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            
            guard let textField = textField as? LineEditorView.TextField, let indexPath = textField.indexPath else {
                return false
            }
            
            if let text = textField.text, let range = Range(range, in: text) {
                if let item = Element(rawValue: text.replacingCharacters(in: range, with: string)) {
                    owner.items[ indexPath.row ] = item
                }
            }

            return true
        }
        
        public func textFieldDidBeginEditing(_ textField: UITextField) {
            guard let textField = textField as? LineEditorView.TextField, let indexPath = textField.indexPath else {
                return
            }
            lines.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
        
        public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
            guard let textField = textField as? LineEditorView.TextField, let indexPath = textField.indexPath else {
                return
            }
            lines.tableView.deselectRow(at: indexPath, animated: false)
        }

    }
    
}


// MARK: - Coordinator::ItemActions
extension LineEditorView.Coordinator  {
    
    func updateItem( at index: Int, withText text: String ) {
        if let item = Element(rawValue: text ) {
            owner.items[ index ] = item
        }

    }
    func addItemAbove() {

        if let indexPath = lines.tableView.indexPathForSelectedRow {
            
            if let newItem = Element(rawValue: "") {

                lines.tableView.performBatchUpdates {
                    owner.items.insert( newItem, at: indexPath.row )
                    self.lines.tableView.insertRows(at: [indexPath], with: .automatic )
                        
                } completion: { [unowned self] success in
                    
                    self.lines.becomeFirstResponder(at: indexPath, withRetries: 0)
                    
                }

            }
        }

    }

    func addItemsBelow( _ items: [Element], at indexPath: IndexPath ) {
        
        let indexes = items
            .enumerated()
            .map { (index, item ) in
                let i = IndexPath( row: indexPath.row + index + 1, section: indexPath.section)
                owner.items.insert( item, at: i.row)
                return i
            }

        lines.tableView.performBatchUpdates {
                
            self.lines.tableView.insertRows(at: indexes, with: .automatic )
            
        } completion: { [unowned self] success in

            if let last = indexes.last {
                self.lines.becomeFirstResponder(at: last, withRetries: 5)
            }
            
            
        }

    }
    

    func addItemBelow() {
        
        if let indexPath = lines.tableView.indexPathForSelectedRow {
            
            if let newItem = Element(rawValue: "" ) {
            
                
                let newIndexPath = IndexPath( row: indexPath.row + 1,
                                              section: indexPath.section )

                lines.tableView.performBatchUpdates {
                    
                    owner.items.insert( newItem, at: newIndexPath.row)
                    self.lines.tableView.insertRows(at: [newIndexPath], with: .automatic )
                    
                } completion: { [unowned self] success in

                    self.lines.becomeFirstResponder(at: newIndexPath, withRetries: 5)
                    
                }
            }
        }
    }

    func cloneItem() {
        
        if let indexPath = lines.tableView.indexPathForSelectedRow {
            
            if let newItem = Element(rawValue: owner.items[ indexPath.row ].rawValue ) {
            
                lines.tableView.performBatchUpdates {
                    owner.items.insert( newItem, at: indexPath.row )
                    self.lines.tableView.insertRows(at: [indexPath], with: .bottom )
                        
                } completion: { [unowned self] success in
                    let newIndexPath = IndexPath( row: indexPath.row + 1,
                                                  section: indexPath.section )
                    self.lines.becomeFirstResponder(at: newIndexPath, withRetries: 0)
                }

            }
        }
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
                
                return rect
            }
        
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ in CGRect.zero }
            
        // 3.
        return Publishers.MergeMany(willShow, willHide).eraseToAnyPublisher()
                
    }
    
    func processSymbol(_ symbol: KeyboardSymbol, on textField: LineEditorView.TextField) {
        
        // [How to programmatically enter text in UITextView at the current cursor position](https://stackoverflow.com/a/35888634/521197)
        if let indexPath = textField.indexPath, let range = textField.selectedTextRange {
            // From your question I assume that you do not want to replace a selection, only insert some text where the cursor is.
            textField.replace(range, withText: symbol.value )
            if let text = textField.text {
                textField.sendActions(for: .valueChanged)
                
                let offset = indexPath.row
                
                updateItem(at: offset, withText: text )

                if let values = symbol.additionalValues {
                    
                    addItemsBelow(values.compactMap { Element( rawValue: $0) }, at: indexPath)
                }
                // toggleCustomKeyobard()
            }
        }
    }


    private func makeCustomKeyboardRect() -> CGRect {
        var customKeyboardRect = keyboardRect
        
        let MAGIC_NUMBER = 102.0
        
        customKeyboardRect.origin.y += MAGIC_NUMBER
        customKeyboardRect.size.height = max( CUSTOM_KEYBOARD_MIN_HEIGHT, customKeyboardRect.size.height)
        customKeyboardRect.size.height -= MAGIC_NUMBER
        
        return customKeyboardRect

    }
    
    // creation Input View
    private func makeCustomKeyboardView( for textField: LineEditorView.TextField ) -> UIView  {
        
        let keyboardView = PlantUMLKeyboardView(
            onHide: toggleCustomKeyobard,
            onPressSymbol: { [weak self] symbol in
                self?.processSymbol(symbol, on: textField)
            })
        
        let controller = UIHostingController( rootView: keyboardView )
                
        controller.view.frame = makeCustomKeyboardRect()
        
        return controller.view
 
    }
    
    func toggleCustomKeyobard() {
        
        print( "toggleCustomKeyobard: \(self.showCustomKeyboard)" )
        
        guard let textField = lines.findFirstTextFieldResponder() else {
            return
        }
        
        showCustomKeyboard.toggle()
        
        if( showCustomKeyboard ) {
            textField.inputView = makeCustomKeyboardView( for: textField )
            
            DispatchQueue.main.async {
                textField.reloadInputViews()
                let _ = textField.becomeFirstResponder()
            }
//            Task {
//
//                let duration = UInt64(0.5 * 1_000_000_000)
//                try? await Task.sleep(nanoseconds: duration )
//
//                textField.reloadInputViews()
//                let _ = textField.becomeFirstResponder()
//
//            }
        }
        else {
            textField.inputView = nil
            textField.reloadInputViews()
        }
        

        
    }

}


// MARK: - Coordinator::UITextField
extension LineEditorView.Coordinator  {
    
    private func setupTextField( _ textField: LineEditorView.TextField, at indexPath: IndexPath, withText text: String ) {
         
        textField.indexPath = indexPath
        
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
            self?.addItemBelow()
        }
        let addBelow = UIBarButtonItem(title: addBelowTitle,
                                       image: nil,
                                       primaryAction: addBelowAction )
        
        let addAboveTitle = NSLocalizedString("Add Above", comment: "")
        let addAboveAction = UIAction(title: addBelowTitle) { [weak self] action in
            self?.addItemAbove()
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
extension LineEditorView.Coordinator  {
    
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
            self?.addItemAbove()
        }
        let addBelowAction =
        UIAction(title: NSLocalizedString("Add Below", comment: ""),
                 image: UIImage(systemName: "arrow.down.square")) { [weak self]  action in
            self?.addItemBelow()
        }
        let cloneRowAction =
        UIAction(title: NSLocalizedString("Clone", comment: ""),
                 image: UIImage(systemName: "plus.square.on.square"),
                 attributes: .destructive) { [weak self] action in
            self?.cloneItem()
        }
        return  UIMenu(title: "", children: [addAboveAction, addBelowAction, cloneRowAction])

    }

}

struct LineEditorView_Previews: PreviewProvider {
    
    public struct Item: RawRepresentable {
        public var rawValue: String
       
        public init( rawValue: String  ) {
            self.rawValue = rawValue
        }
    }
    
    static var previews: some View {
        LineEditorView<Item>( items: Binding.constant( [
            Item(rawValue: "Item1"),
            Item(rawValue: "Item2"),
            Item(rawValue: "Item3"),
            Item(rawValue: "Item4"),
            Item(rawValue: "Item5"),
            Item(rawValue: "Item6")
        ] ))
    }
}
