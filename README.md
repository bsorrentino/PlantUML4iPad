# PlantUML4iPad

## Description

> Native PlantUML Editor thought for iPad providing a improved user experience to use this popular "diagram-as-code" tool 

This is a native PlantUML editor app for iPad. It allows using iPad to draw diagrams in effective way. It includes use of AI to helping drawing process. take note that to enable AI features you **MUST HAVE** a valid "OpenAI API key" i.e. OpenAI Paid Account

_Promotional Text_ 🤞

> This is a (first  🤔) native Plantuml Editor App for iPad with AI capabilities. Developed by a Plantuml lover to enjoy the writing of diagrams on this excellent device

## Features 🦾

1. Create,Update,Delete plantUML Documents
2. Share Documents with iCLoud
3. OpenAI integration
    > **You MUST HAVE a valid [OpenAI] API KEY (i.e. Paid Account)** to use this feature. Such secrets will be stored in device's keychain
    * Drawing
        * Draw Diagram using either Pencil or Fingers.
        * Processing hand drawn diagram through [OpenAI Vision API] (_gpt-4-vision-preview_) to automatically genearte plantUML script.
        * PlantUML script will include alse a legend with detailed description of drawing.
    * Prompt     
        * Prompt your diagram request in natural language
        * Undo Prompt
        * Prompt's History 
        * choose AI Model (_gpt-3.5-turbo or gpt-4_)
4. Text Editor
    * Auto save over modification
    * Provide **syntax highlighting** and auto completion **diagram snippets** through [ace] editor
5. Diagram Preview 
    > Preview relies on [PlantUML online server] so it requires internet connection
    * Built in cache management
    * Scale to fit
    * Share Image (AirDrop, iCloud, Other App, ...)

**Take a Note:**

* **Release 3.0**
    > From release `3.0` it is possible also hand drawn diagram using either Pencil or Fingers.

* **Release 2.0**
    > From release `2.0` the PlantUML Custom Keyboard has been disabled because not compatible with the new editor based on [ace]

## App Store

See the App on [App Store](https://apps.apple.com/us/app/plantuml-app/id6444164984) 👀

## References

Below all references that helped to develop such App

* [Get a binding from an environment value in SwiftUI](https://stackoverflow.com/q/69731360/521197)
* [How can I set an image tint in SwiftUI?](https://stackoverflow.com/a/73289182/521197)
* [Get the current first responder without using a private API](https://stackoverflow.com/a/1823360/521197)
* [Split Picture in tiles and put in array](https://stackoverflow.com/a/73628496/521197)
* [SwiftUI exporting or sharing files](https://stackoverflow.com/a/56828100/521197)
* [Customizing Toggle with ToggleStyle](https://www.hackingwithswift.com/quick-start/swiftui/customizing-toggle-with-togglestyle)
* [How to remove all the spaces in a String?](https://stackoverflow.com/a/34940120/521197)
* [Perform a full swipe left action in UI Tests?](https://stackoverflow.com/a/51639973)
* [Managing Focus in SwiftUI List Views](https://peterfriese.dev/posts/swiftui-list-focus/)
* [How to access back bar button item in universal way under UITests in Xcode?](https://stackoverflow.com/a/38595332/521197)
* [Regular Expression Capture Groups in Swift](https://www.advancedswift.com/regex-capture-groups/)
* [iOS UI testing: element descendants](https://pgu.dev/2020/12/20/ios-ui-tests-element-descendants.html)
* [SwiftUI Let View disappear automatically](https://stackoverflow.com/a/60820491/521197)
* [How to scroll a Form to a specific UI element in SwiftUI](https://stackoverflow.com/a/65777080/521197)
* [Conditional modifier](https://designcode.io/swiftui-handbook-conditional-modifier)
* [How to Display Web Page Using WKWebView](https://www.appcoda.com/swiftui-wkwebview/)
* [Document based app shows 2 back chevrons on iPad](https://stackoverflow.com/a/74245034/521197)
* [Compressing and Decompressing Data with Buffer Compression](https://developer.apple.com/documentation/accelerate/compressing_and_decompressing_data_with_buffer_compression)
* [How to detect device rotation](https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-device-rotation)
* [How to convert a SwiftUI view to an image](https://www.hackingwithswift.com/quick-start/swiftui/how-to-convert-a-swiftui-view-to-an-image)
* [Button border with corner radius in Swift UI](https://stackoverflow.com/a/62544642/521197)
* [SwiftUI: Forcing an Update](https://stackoverflow.com/a/65095862/521197)
* [How can I add caching to AsyncImage](https://stackoverflow.com/a/70916651/521197)
* [Open-source themes for PlantUML diagrams](https://bschwarz.github.io/puml-themes/gallery.html)
* [iOS Localization and Internationalization Testing with XCUITest](https://medium.com/xcblog/ios-localization-and-internationalization-testing-with-xcuitest-495747a74775)
* [How to percent encode a URL String](https://useyourloaf.com/blog/how-to-percent-encode-a-url-string/)
* [Sccess TextEditor from XCUIApplication](https://stackoverflow.com/a/69522578/521197)

[openai]: https://openai.com
[ace]: https://ace.c9.io
[OpenAI Vision API]: https://platform.openai.com/docs/guides/vision
[PlantUML online server]: https://plantuml.com/server