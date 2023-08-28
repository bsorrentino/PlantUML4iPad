//
//  CodeWebView.swift
//  CodeViewer
//
//  Created by phucld on 8/20/20.
//  Copyright © 2020 Dwarves Foundattion. All rights reserved.
//

import WebKit
import Combine

#if os(OSX)
    import AppKit
    public typealias CustomView = NSView
#elseif os(iOS)
    import UIKit
    public typealias CustomView = UIView
#endif
 
// MARK: JavascriptFunction

// JS Func
typealias JavascriptCallback = (Result<Any?, Error>) -> Void
private struct JavascriptFunction {
    
    let functionString: String
    let callback: JavascriptCallback?
    
    init(functionString: String, callback: JavascriptCallback? = nil) {
        self.functionString = functionString
        self.callback = callback
    }
}

public class CodeWebView: CustomView {
    
    private struct Constants {
        static let aceEditorDidReady = "aceEditorDidReady"
        static let aceEditorDidChanged = "aceEditorDidChanged"
    }
    
    private lazy var webview: WKWebView = {
        let preferences = WKPreferences()
        var userController = WKUserContentController()
        userController.add(self, name: Constants.aceEditorDidReady) // Callback from Ace editor js
        userController.add(self, name: Constants.aceEditorDidChanged)
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.userContentController = userController
        let webView = WKWebView(frame: bounds, configuration: configuration)
        
        #if os(OSX)
        webView.setValue(true, forKey: "drawsTransparentBackground") // Prevent white flick
        #elseif os(iOS)
        webView.isOpaque = false
        #endif
        
        return webView
    }()
    
    var textDidChanged: ((String) -> Void)?

    private var currentContent: String = ""
    private var pageLoaded = false
    private var pendingFunctions = [JavascriptFunction]()
    
    private var reloadCancellation:Cancellable?

    var navigationDelegate:WKNavigationDelegate? {
        get {
            return webview.navigationDelegate
        }
        set {
            webview.navigationDelegate = newValue
        }
    }
    
    override init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        initWebView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initWebView()
    }
    
    func setContent(_ value: String) {
        
        guard currentContent != value else {
            return
        }
        
        currentContent = value
        
        //
        // It's tricky to pass FULL JSON or HTML text with \n or "", ... into JS Bridge
        // Have to wrap with `data_here`
        // And use String.raw to prevent escape some special string -> String will show exactly how it's
        // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Template_literals
        //
        let first = "var content = String.raw`"
        let content = """
        \(value)
        """
        let end = "`; editor.setValue(content);"
        
        let script = first + content + end
        callJavascript(javascriptString: script)
        
        
    }
    
    func setFocus() {
        callJavascript(javascriptString: "editor.focus();")
    }
    func setTheme(_ theme: Theme) {
        callJavascript(javascriptString: "editor.setTheme('ace/theme/\(theme.rawValue)');")
    }
    
    func setMode(_ mode: Mode) {
        callJavascript(javascriptString: "editor.session.setMode('ace/mode/\(mode.rawValue)');")
    }
    
    func setReadOnly(_ isReadOnly: Bool) {
        callJavascript(javascriptString: "editor.setReadOnly(\(isReadOnly));")
    }
    
    func setFontSize(_ fontSize: CGFloat) {
        let script = "document.getElementById('editor').style.fontSize='\(fontSize)px';"
        callJavascript(javascriptString: script)
    }

    func setShowGutter(_ show: Bool) {
        callJavascript(javascriptString: "editor.renderer.setShowGutter(\(show));")
    }

    func setShowLineNumbers(_ show: Bool) {
        let jscode = "editor.setOptions({ showLineNumbers: \(show) })";
        callJavascript(javascriptString: jscode )
    }
    
    func clearSelection() {
        let script = "editor.clearSelection();"
        callJavascript(javascriptString: script)
    }
    
    func getAnnotation(callback: @escaping JavascriptCallback) {
        let script = "editor.getSession().getAnnotations();"
        callJavascript(javascriptString: script) { result in
           callback(result)
        }
    }
    
}

extension CodeWebView {
    
    private func initWebView() {
        
        reloadCancellation = NotificationCenter.default.publisher(for: NSNotification.Name("reload"))
            .sink(receiveValue: { [unowned self] _ in
                webview.reloadFromOrigin()
            })

        webview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webview)
        webview.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        webview.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        webview.topAnchor.constraint(equalTo: topAnchor).isActive = true
        webview.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        guard let bundlePath = Bundle.module.path(forResource: "ace", ofType: "bundle"),
            let bundle = Bundle(path: bundlePath),
            let indexPath = bundle.path(forResource: "index", ofType: "html") else {
                fatalError("Ace editor is missing")
        }
        
        let data = try! Data(contentsOf: URL(fileURLWithPath: indexPath))
        webview.load(data, mimeType: "text/html", characterEncodingName: "utf-8", baseURL: bundle.resourceURL!)
    }
    private func addFunction(function:JavascriptFunction) {
        pendingFunctions.append(function)
    }
    
    private func callJavascriptFunction(function: JavascriptFunction) {
        webview.evaluateJavaScript(function.functionString) { (response, error) in
            if let error = error {
                function.callback?(.failure(error))
            }
            else {
                function.callback?(.success(response))
            }
        }
    }
    
    private func callPendingFunctions() {
        for function in pendingFunctions {
            callJavascriptFunction(function: function)
        }
        pendingFunctions.removeAll()
    }
    
    private func callJavascript(javascriptString: String, callback: JavascriptCallback? = nil) {
        if pageLoaded {
            callJavascriptFunction(function: JavascriptFunction(functionString: javascriptString, callback: callback))
        }
        else {
            addFunction(function: JavascriptFunction(functionString: javascriptString, callback: callback))
        }
    }
}

// MARK: WKScriptMessageHandler

extension CodeWebView: WKScriptMessageHandler {

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

        // is Ready
        if message.name == Constants.aceEditorDidReady {
            pageLoaded = true
            callPendingFunctions()
            return
        }
        
        // is Text change
        if message.name == Constants.aceEditorDidChanged,
           let text = message.body as? String {
            
            self.textDidChanged?(text)

            return
        }
    }
}
