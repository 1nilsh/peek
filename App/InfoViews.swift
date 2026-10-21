import PeekCore
import PeekFormats
import SwiftUI
import UniformTypeIdentifiers

struct SetupView: View {
    var body: some View {
        Form {
            Section {
                Label("Keep Peek in your Applications folder and open it once, so macOS registers its extensions.", systemImage: "1.circle")
                Label("Turn on Peek under Quick Look in System Settings → General → Login Items & Extensions.", systemImage: "2.circle")
                Label("Select a file in Finder and press Space.", systemImage: "3.circle")
                Button("Open Login Items & Extensions…") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!)
                }
            } header: {
                Text("Getting started")
            }
            Section {
                Text("Another app's Quick Look extension may claim the same file types. If Peek isn't used for a file, use Check File to see its type, and try turning off other Quick Look extensions.")
                Text("Finder caches thumbnails. Changed settings apply to thumbnails once a file changes or the cache is cleared with `qlmanage -r cache` in Terminal.")
            } header: {
                Text("Troubleshooting")
            }
        }
        .formStyle(.grouped)
    }
}

struct SupportedTypesView: View {
    struct Row: Identifiable {
        let id: String
        let format: String
        let description: String
        let extensions: String
        let thumbnail: String
    }

    private let rows: [Row] = FormatRegistry.renderers.flatMap { renderer in
        renderer.contentTypes.sorted().map { id in
            let type = UTType(id)
            return Row(
                id: id,
                format: renderer.displayName,
                description: type?.localizedDescription ?? "Not declared on this Mac",
                extensions: (type?.tags[.filenameExtension] ?? []).map { ".\($0)" }.joined(separator: " "),
                thumbnail: FormatRegistry.systemThumbnailTypes.contains(id) ? "macOS" : "Peek")
        }
    }

    var body: some View {
        Table(rows) {
            TableColumn("Format", value: \.format).width(min: 80, ideal: 100)
            TableColumn("Kind", value: \.description)
            TableColumn("Extensions", value: \.extensions)
            TableColumn("Thumbnail", value: \.thumbnail).width(min: 60, ideal: 70)
            TableColumn("Content Type", value: \.id)
        }
        .textSelection(.enabled)
    }
}

struct CheckFileView: View {
    struct Result {
        let name: String
        let type: UTType?
        let preview: String
        let thumbnail: String
    }

    @State private var result: Result?
    @State private var isTargeted = false
    @State private var isImporting = false

    var body: some View {
        Form {
            Section {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.doc").font(.largeTitle).foregroundStyle(.secondary)
                    Text("Drop a file here")
                    Button("Choose File…") { isImporting = true }
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(isTargeted ? Color.accentColor.opacity(0.1) : .clear, in: .rect(cornerRadius: 8))
                .dropDestination(for: URL.self) { urls, _ in
                    urls.first.map(check)
                    return urls.first != nil
                } isTargeted: { isTargeted = $0 }
            }
            if let result {
                Section(result.name) {
                    LabeledContent("Content type", value: result.type?.identifier ?? "Unknown")
                    LabeledContent("Kind", value: result.type?.localizedDescription ?? "–")
                    if result.type?.isDynamic == true {
                        Text("macOS has no declared type for this extension, so Quick Look extensions can't claim it.")
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Preview", value: result.preview)
                    LabeledContent("Thumbnail", value: result.thumbnail)
                    if let type = result.type {
                        LabeledContent("Conforms to", value: type.supertypes.map(\.identifier).sorted().joined(separator: ", "))
                    }
                }
                .textSelection(.enabled)
            }
        }
        .formStyle(.grouped)
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.item]) { result in
            if case .success(let url) = result { check(url) }
        }
    }

    private func check(_ url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType
        let handledBy = type.flatMap(FormatRegistry.renderer).map { "Peek (\($0.displayName))" } ?? "Not handled by Peek"
        let systemThumbnail = type.map { FormatRegistry.systemThumbnailTypes.contains($0.identifier) } ?? false
        result = Result(name: url.lastPathComponent, type: type, preview: handledBy, thumbnail: systemThumbnail ? "macOS" : handledBy)
    }
}
