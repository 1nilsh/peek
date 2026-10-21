import AppKit
import PeekCore
import SwiftUI

struct SettingsWithPreview<Form: View>: View {
    let sample: Sample
    @ViewBuilder let form: Form

    var body: some View {
        // HStack rather than HSplitView: the AppKit split view reports its own size and widens the detail column.
        HStack(spacing: 0) {
            form
                .formStyle(.grouped)
                .frame(width: 340)
            Divider()
            PreviewPane(initialSample: sample)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct AppearanceSettings: View {
    @Environment(SettingsStore.self) private var store
    @State private var confirmingRefresh = false
    @State private var refreshError: String?

    private static let monospacedFamilies: [String] = NSFontManager.shared.availableFontFamilies.filter { family in
        NSFont(name: family, size: 12)?.fontDescriptor.symbolicTraits.contains(.monoSpace) == true
    }

    var body: some View {
        @Bindable var store = store
        Form {
            Section {
                Picker("Theme", selection: $store.settings.themeID) {
                    ForEach(Theme.all) { Text($0.name).tag($0.id) }
                }
                Picker("Appearance", selection: $store.settings.appearance) {
                    Text("System").tag(Settings.Appearance.system)
                    Text("Light").tag(Settings.Appearance.light)
                    Text("Dark").tag(Settings.Appearance.dark)
                }
                Picker("Font", selection: $store.settings.fontFamily) {
                    Text("System Monospaced").tag("")
                    Divider()
                    ForEach(Self.monospacedFamilies, id: \.self) { Text($0).tag($0) }
                }
                LabeledContent("Size") {
                    Stepper(value: $store.settings.fontSize, in: 8...28, step: 1) {
                        Text("\(Int(store.settings.fontSize)) pt").monospacedDigit()
                    }
                }
            } footer: {
                Text("System follows the light or dark appearance of macOS.")
            }
            Section {
                Toggle("Dark thumbnails", isOn: $store.settings.darkThumbnails)
                LabeledContent("Thumbnail text") {
                    let sizes = Settings.ThumbnailTextSize.allCases
                    HStack {
                        Slider(
                            value: Binding(
                                get: { Double(sizes.firstIndex(of: store.settings.thumbnailTextSize) ?? 0) },
                                set: { store.settings.thumbnailTextSize = sizes[Int($0.rounded())] }),
                            in: 0...Double(sizes.count - 1), step: 1)
                        Text(store.settings.thumbnailTextSize.title)
                            .frame(width: 70, alignment: .leading)
                    }
                }
                LabeledContent("Finder thumbnails") {
                    Button("Refresh…") { confirmingRefresh = true }
                }
                .confirmationDialog("Relaunch Finder?", isPresented: $confirmingRefresh) {
                    Button("Relaunch Finder") {
                        Task { refreshError = await refreshThumbnails() }
                    }
                } message: {
                    Text("Peek clears the thumbnail cache, then relaunches Finder so it shows the new thumbnails.")
                }
                if let refreshError {
                    Text(refreshError)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }
            } footer: {
                Text("Finder keeps thumbnails it has already made until the file changes. Refresh discards them.")
            }
            Section("Code") {
                Toggle("Wrap long lines", isOn: $store.settings.wordWrap)
                Toggle("Show line numbers", isOn: $store.settings.lineNumbers)
                Picker("Tab width", selection: $store.settings.tabWidth) {
                    ForEach([2, 4, 8], id: \.self) { Text("\($0) spaces").tag($0) }
                }
            }
            ResetSection()
        }
    }

    /// Returns an error message, or nil on success.
    private func refreshThumbnails() async -> String? {
        guard await ThumbnailCache.reset() else {
            return "Couldn't clear the thumbnail cache. Run `qlmanage -r cache` in Terminal, then relaunch Finder."
        }
        guard await ThumbnailCache.relaunchFinder() else {
            return "Couldn't relaunch Finder. Allow Peek to control Finder in System Settings → Privacy & Security → Automation, or Option-right-click Finder in the Dock and choose Relaunch."
        }
        return nil
    }
}

struct MarkdownSettings: View {
    @Environment(SettingsStore.self) private var store

    var body: some View {
        @Bindable var store = store
        Form {
            Section {
                Toggle("Show front matter", isOn: $store.settings.showFrontMatter)
            } footer: {
                Text("YAML front matter at the top of a file is shown as a table.")
            }
            Section {
                Picker("Raw HTML", selection: $store.settings.rawHTML) {
                    Text("Clean up").tag(Settings.RawHTMLMode.sanitize)
                    Text("Show as text").tag(Settings.RawHTMLMode.escape)
                }
                .pickerStyle(.radioGroup)
            } footer: {
                Text("Quick Look runs scripts in previews. \"Clean up\" keeps harmless formatting such as images, alignment and collapsible sections, and removes scripts, styles and anything that loads from the internet. \"Show as text\" displays HTML as written.")
            }
            Section {
                Toggle("Load remote images", isOn: $store.settings.allowRemoteImages)
            } footer: {
                Text("Remote images reveal to their server that, and when, a file was previewed. Local images are always shown.")
            }
        }
    }
}

struct SourceCodeSettings: View {
    @Environment(SettingsStore.self) private var store

    var body: some View {
        @Bindable var store = store
        Form {
            Section {
                Picker("Highlight up to", selection: $store.settings.highlightLimit) {
                    ForEach([100_000, 200_000, 500_000, 1_000_000], id: \.self) {
                        Text(ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .file)).tag($0)
                    }
                }
            } footer: {
                Text("Larger files are cut off at this size. Highlighting takes roughly 0.2 s per 100 KB.")
            }
        }
    }
}

private extension PeekCore.Settings.ThumbnailTextSize {
    var title: String {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        case .veryLarge: "Very large"
        }
    }
}

private struct ResetSection: View {
    @Environment(SettingsStore.self) private var store

    var body: some View {
        Section {
            Button("Restore Defaults", role: .destructive) { store.reset() }
                .disabled(store.settings == Settings())
        }
    }
}
