import PeekCore
import SwiftUI

@main
struct PeekApp: App {
    var body: some Scene {
        Window("Peek", id: "main") {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}

struct ContentView: View {
    @State private var lastWrite = AppGroup.defaults?.string(forKey: "spike.lastWrite")

    var body: some View {
        Form {
            Section("Setup") {
                Text("Enable Peek in System Settings → General → Login Items & Extensions → Quick Look.")
            }
            Section("App Group (spike S3)") {
                LabeledContent("Identifier", value: AppGroup.identifier)
                LabeledContent("Last write", value: lastWrite ?? "(nothing)")
                Button("Write timestamp") {
                    let value = Date.now.formatted(date: .omitted, time: .standard)
                    AppGroup.defaults?.set(value, forKey: "spike.lastWrite")
                    lastWrite = AppGroup.defaults?.string(forKey: "spike.lastWrite")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
    }
}
