import PeekCore
import PeekSourceCode
import UniformTypeIdentifiers

/// All formats compiled into Peek. To add a format, append its renderer here and list its
/// content types in project.yml (`FormatRegistryTests` checks both agree).
public enum FormatRegistry {
    public static let renderers: [any FormatRenderer] = [
        SourceCodeRenderer(),
    ]

    public static var contentTypes: Set<String> { Set(renderers.flatMap(\.contentTypes)) }

    /// Exact match only: Quick Look itself dispatches on exact identifiers, not conformance.
    public static func renderer(for type: UTType) -> (any FormatRenderer)? {
        renderers.first { $0.contentTypes.contains(type.identifier) }
    }
}
