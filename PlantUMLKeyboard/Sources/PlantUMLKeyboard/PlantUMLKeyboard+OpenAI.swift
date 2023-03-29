//
//  SwiftUIView.swift
//  
//
//  Created by Bartolomeo Sorrentino on 29/03/23.
//

import SwiftUI

struct OpenAIView: View {
    
    var apiKey: String {
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String, !apiKey.isEmpty {
            return "api key \(apiKey)"
        }
        else {
            return "api key not found!"

        }
        

    }
    var body: some View {
        Text(apiKey)
    }
}

struct OpenAIView_Previews: PreviewProvider {
    static var previews: some View {
        OpenAIView()
    }
}
