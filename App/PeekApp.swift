import PeekCore
import SwiftUI

@main
struct PeekApp: App {
    @State private var store = SettingsStore()

    var body: some Scene {
        Window("Peek", id: "main") {
            ContentView()
                .environment(store)
                .frame(minWidth: 900, minHeight: 560)
        }
        .defaultSize(width: 1040, height: 680)
        .windowResizability(.contentMinSize)
    }
}

/// The settings shown in the app; every change is written to the App Group for the extensions.
@Observable final class SettingsStore {
    var settings = Settings.load() {
        didSet { settings.save() }
    }

    func reset() { settings = Settings() }
}

enum Pane: String, CaseIterable, Identifiable {
    case setup, appearance, markdown, sourceCode, types, check

    var id: Self { self }

    var title: String {
        switch self {
        case .setup: "Setup"
        case .appearance: "Appearance"
        case .markdown: "Markdown"
        case .sourceCode: "Source Code"
        case .types: "Supported Types"
        case .check: "Check File"
        }
    }

    var systemImage: String {
        switch self {
        case .setup: "checklist"
        case .appearance: "paintpalette"
        case .markdown: "text.document"
        case .sourceCode: "chevron.left.forwardslash.chevron.right"
        case .types: "list.bullet.rectangle"
        case .check: "magnifyingglass"
        }
    }
}

struct ContentView: View {
    @State private var pane: Pane? = .setup

    var body: some View {
        NavigationSplitView {
            List(Pane.allCases, selection: $pane) { pane in
                Label(pane.title, systemImage: pane.systemImage).tag(pane)
            }
            .navigationSplitViewColumnWidth(180)
        } detail: {
            Group {
                switch pane ?? .setup {
                case .setup: SetupView()
                case .appearance: SettingsWithPreview(sample: .swift) { AppearanceSettings() }
                case .markdown: SettingsWithPreview(sample: .markdown) { MarkdownSettings() }
                case .sourceCode: SettingsWithPreview(sample: .swift) { SourceCodeSettings() }
                case .types: SupportedTypesView()
                case .check: CheckFileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle((pane ?? .setup).title)
        }
    }
}
