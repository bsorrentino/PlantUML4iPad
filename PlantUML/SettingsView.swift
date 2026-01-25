//
//  SettingsView.swift
//  PlantUMLApp
//
//  Created by bsorrentino on 25/01/26.
//

import SwiftUI
import AppSecureStorage

let allModels = [
    "OpenAI": ( vision: [
                    //"gpt-5",
                    "gpt-4o",
                    //"gpt-5-mini",
                    //"gpt-5-nano",
                    "gpt-4.1"
                ],
                prompt: [
                    //"gpt5-nano",
                    //"gpt-5-mini",
                    "gpt-4o-mini",
                    //"gpt-5",
                    "gpt-4o"
                ])
    ]

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var serviceAI: AIObservableService
    @State private var hideOpenAISecrets = true
    

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Provider")) {
                    Picker("Provider", selection: $serviceAI.provider) {
                        ForEach(AIProvider.allCases) { provider in
                            Text(provider.rawValue).tag(provider)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section(header: Text("\($serviceAI.provider.id) configuration")) {
                    Section {
                        SecureToggleField( "Api Key", value: $serviceAI.inputApiKey, hidden: hideOpenAISecrets)
                    }
                    header: {
                        HStack {
                            Text("Api Key").font(Font.callout)
                            HideToggleButton(hidden: $hideOpenAISecrets)
                            
                            Text("these data will be stored in onboard secure keychain")
                                .font(Font.callout)
                                .foregroundColor(.secondary)
                                .padding( .leading, 30)
                        }
                        .id( "openai-secret")

                    }
                }
                Section(header: Text("Model")) {
                    let allModelsByProvider = allModels[serviceAI.provider.id]
                    Picker("Vision", selection: $serviceAI.visionModel) {
                        ForEach(allModelsByProvider?.vision ?? [], id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.menu)
                        
                    Picker("Prompt", selection: $serviceAI.promptModel) {
                        ForEach(allModelsByProvider?.prompt ?? [], id: \.self) { model in
                                Text(model).tag(model)
                            }
                    }
                    .pickerStyle(.menu)

                }
                
                Button("Save") {
                    serviceAI.commitSettings()
                    dismiss()
                }
                .frame(maxWidth: .infinity)

                
            }
            .navigationTitle("AI Settings")
            .navigationBarTitleDisplayMode(.large)
            
        }
    }
    
}

#if DEBUG
#Preview {
    SettingsView(serviceAI: AIObservableService())
}
#endif

