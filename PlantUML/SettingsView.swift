import SwiftUI
import AppSecureStorage

/// Enum for selecting the AI Provider
enum AIProvider: String, CaseIterable, Identifiable {
    case openAI = "OpenAI"
    case ollama = "Ollama"
    //case gemini = "Gemini"
    
    var id: String { rawValue }
}

/// Settings Model for SettingsView binding
@Observable
class SettingsViewModel {
    var provider: AIProvider = .openAI
    var ollamaURL: String = ""
    
    @ObservationIgnored
    let allModels = [
        "OpenAI": ( vision: ["gpt-4o", "gpt-4-vision"],
                    prompt: ["gpt-4o-mini", "gpt-3.5-turbo"])
        ]
            
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var openAIService: OpenAIObservableService
    @State var viewModel: SettingsViewModel = SettingsViewModel()
    @State private var hideOpenAISecrets = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Provider")) {
                    Picker("Provider", selection: $viewModel.provider) {
                        ForEach(AIProvider.allCases) { provider in
                            Text(provider.rawValue).tag(provider)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section(header: Text("\(viewModel.provider.id) configuration")) {
                    if viewModel.provider == .ollama {
                        TextField("URL", text: $viewModel.ollamaURL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                    }
                    else {
                        Section {
                            SecureToggleField( "Api Key", value: $openAIService.inputApiKey, hidden: hideOpenAISecrets)
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
                }
                Section(header: Text("Model")) {
                    if viewModel.provider == .ollama {
                        OllamaModels
                    }
                    else {
                        OtherModels
                    }
                    
                }
                
                Button("Done") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)

                
            }
            .navigationTitle("AI Settings")
            .navigationBarTitleDisplayMode(.large)
            
        }
    }
    
    var OtherModels: some View {
        let allModelsByProvider = viewModel.allModels[viewModel.provider.id]
        return Group {
            Picker("Vision", selection: $openAIService.visionModel) {
                ForEach(allModelsByProvider?.vision ?? [], id: \.self) { model in
                    Text(model).tag(model)
                }
            }
            .pickerStyle(.menu)
            
            Picker("Prompt", selection: $openAIService.promptModel) {
                ForEach(allModelsByProvider?.prompt ?? [], id: \.self) { model in
                        Text(model).tag(model)
                    }
            }
            .pickerStyle(.menu)
        }

    }
    
    var OllamaModels: some View {
        Group {
            TextField("Vision", text: $openAIService.visionModel)
                .keyboardType(.default)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            TextField("Prompt", text: $openAIService.promptModel)
                .keyboardType(.default)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
    }
}

#if DEBUG
#Preview {
    SettingsView(openAIService: OpenAIObservableService())
}
#endif

