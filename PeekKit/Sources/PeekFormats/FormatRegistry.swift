import PeekCore
import PeekMarkdown
import PeekSourceCode
import UniformTypeIdentifiers

/// All formats compiled into Peek. To add a format, append its renderer here and list its
/// content types in project.yml (`FormatRegistryTests` checks both agree).
public enum FormatRegistry {
    public static let renderers: [any FormatRenderer] = [
        MarkdownRenderer(),
        SourceCodeRenderer(),
    ]

    public static var contentTypes: Set<String> { Set(renderers.flatMap(\.contentTypes)) }

    /// Handled types whose thumbnails macOS always draws itself, verified on macOS 26.6
    /// (docs/DEVELOPMENT.md, content type caveats). The thumbnail extension still declares them.
    public static let systemThumbnailTypes: Set<String> = [
        "net.daringfireball.markdown",
        "public.assembly-source",
        "public.json",
    ]

    /// Exact match only: Quick Look itself dispatches on exact identifiers, not conformance.
    public static func renderer(for type: UTType) -> (any FormatRenderer)? {
        renderers.first { $0.contentTypes.contains(type.identifier) }
    }
}
