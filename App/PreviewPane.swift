import PeekCore
import PeekFormats
import SwiftUI
import WebKit

/// Sample files bundled from `Fixtures/samples/` (see project.yml).
enum Sample: String, CaseIterable, Identifiable {
    case markdown = "sample.md"
    case swift = "sample.swift"
    case python = "sample.py"

    var id: Self { self }
    var title: String { rawValue }
    var url: URL? { Bundle.main.url(forResource: rawValue, withExtension: nil, subdirectory: "samples") }
}

/// Live preview of a sample, rendered by the same code as the extensions.
struct PreviewPane: View {
    @Environment(SettingsStore.self) private var store
    @State private var sample: Sample
    @State private var appearance: ColorScheme?

    init(initialSample: Sample) {
        _sample = State(initialValue: initialSample)
    }

    var body: some View {
        let rendered = render()
        // A fixed appearance setting overrides the simulated system appearance.
        let forced = store.settings.appearance.colorScheme
        VStack(spacing: 0) {
            HStack {
                Picker("Sample", selection: $sample) {
                    ForEach(Sample.allCases) { Text($0.title).tag($0) }
                }
                .fixedSize()
                Spacer()
                Picker("Appearance", selection: forced == nil ? $appearance : .constant(forced)) {
                    Text("System").tag(ColorScheme?.none)
                    Text("Light").tag(ColorScheme?.some(.light))
                    Text("Dark").tag(ColorScheme?.some(.dark))
                }
                .pickerStyle(.segmented)
                .fixedSize()
                .disabled(forced != nil)
            }
            .labelsHidden()
            .padding(8)
            Divider()
            HTMLView(html: rendered.html, appearance: forced ?? appearance)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .bottomTrailing) {
                    if let thumbnail = rendered.thumbnail {
                        Image(nsImage: thumbnail)
                            .shadow(radius: 3)
                            .padding(12)
                            .help("Finder thumbnail")
                    }
                }
        }
    }

    private func render() -> (html: String, thumbnail: NSImage?) {
        guard
            let url = sample.url,
            let type = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType,
            let renderer = FormatRegistry.renderer(for: type)
        else { return ("<p>Sample unavailable.</p>", nil) }
        let context = RenderContext(settings: store.settings, contentType: type)
        do {
            let document = try renderer.preview(of: url, context: context)
            // WKWebView can't resolve Quick Look's cid: attachments; inline them as data: URIs.
            var html = document.html
            for (id, attachment) in document.attachments {
                let mime = attachment.contentType.preferredMIMEType ?? "application/octet-stream"
                html = html.replacingOccurrences(of: "cid:\(id)", with: "data:\(mime);base64,\(attachment.data.base64EncodedString())")
            }
            let text = try renderer.thumbnail(of: url, context: context)
            let size = ThumbnailPage.contextSize(fitting: CGSize(width: 128, height: 128))
            let background = context.thumbnailPalette.background.nsColor
            let thumbnail = NSImage(size: size, flipped: false) { _ in
                ThumbnailPage.draw(text, contextSize: size, background: background)
            }
            return (html, thumbnail)
        } catch {
            return ("<p>\(error.localizedDescription.htmlEscaped)</p>", nil)
        }
    }
}

private extension PeekCore.Settings.Appearance {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

struct HTMLView: NSViewRepresentable {
    let html: String
    let appearance: ColorScheme?

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.underPageBackgroundColor = .clear
        return view
    }

    func updateNSView(_ view: WKWebView, context: Context) {
        view.appearance = appearance.map { NSAppearance(named: $0 == .dark ? .darkAqua : .aqua) } ?? nil
        if context.coordinator.html != html {
            context.coordinator.html = html
            view.loadHTMLString(html, baseURL: nil)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var html: String?
    }
}
