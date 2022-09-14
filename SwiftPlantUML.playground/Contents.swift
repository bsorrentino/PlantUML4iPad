import UIKit
import PlantUMLFramework

var greeting = "Hello, playground"

let text = "/‘ of participant '/"

var result = text

text.enumerated().forEach { index, ch in
    let v = ch.unicodeScalars.first!
    print( v, v.value )
    if( !ch.isASCII ) {
        if v.value == 8216 {
            var chars = Array(text)
            chars[index] = "\u{27}" // 39
            result = String( chars )
        }
    }
//    print( "\($0)" )
//    if( !$0.isASCII ) {
//        let v = $0.unicodeScalars.first!
//        print( v, v.value )
//    }
//    else {
//        print( "\($0.asciiValue!)" )
//    }
}
let clazz = SyntaxStructure( rawValue: result )

let script = PlantUMLScript( items: [clazz] )

script.text

let presenter = PlantUMLBrowserPresenter( format: .imagePng)

presenter.url( of: script )
