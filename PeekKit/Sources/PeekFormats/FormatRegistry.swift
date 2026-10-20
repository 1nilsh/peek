import PeekCore
import PeekSourceCode
import UniformTypeIdentifiers

/// All formats compiled into Peek. To add a format, append its renderer here and list its
/// content types in project.yml (`FormatRegistryTests` checks both agree).
public enum FormatRegistry {
    /// Order matters for conformance matches: specific formats before generic ones.
    public static let renderers: [any FormatRenderer] = [
        SourceCodeRenderer(),
    ]

    public static var contentTypes: Set<String> { Set(renderers.flatMap(\.contentTypes)) }

    /// Exact identifier match first, then the first renderer claiming a supertype of `type`.
    public static func renderer(for type: UTType) -> (any FormatRenderer)? {
        if let exact = renderers.first(where: { $0.contentTypes.contains(type.identifier) }) { return exact }
        return renderers.first { renderer in
            renderer.contentTypes.contains { UTType($0).map(type.conforms(to:)) ?? false }
        }
    }
}
