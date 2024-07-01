import Foundation

/// presentation formats supported to render PlantUML scripts in browser
public enum BrowserPresentationFormat {
    /// image only (as .png)
    case imagePng
    /// editable script and corresponding diagram
    case ASCIIArt
}

let planttext_baseurl = "https://www.planttext.com/api/plantuml"
let plantuml_baseurl = "https://www.plantuml.com/plantuml"

public func plantUMLUrl( of script: PlantUMLScript, format: BrowserPresentationFormat ) -> URL {
    
    let encodedText = script.encodeText()
    let url: URL!
    switch format {
    case .imagePng:
        url = URL(string: "\(plantuml_baseurl)/png/\(encodedText)")
    case .ASCIIArt:
        url = URL(string: "\(plantuml_baseurl)/txt/\(encodedText)")!
    }
    return url

}
