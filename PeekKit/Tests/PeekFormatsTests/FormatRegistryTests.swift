import Foundation
import PeekCore
import PeekSourceCode
import Testing
import UniformTypeIdentifiers
@testable import PeekFormats

@Suite struct FormatRegistryTests {
    static let projectYML: String = {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return (try? String(contentsOf: root.appending(path: "project.yml"), encoding: .utf8)) ?? ""
    }()

    /// Items of the `QLSupportedContentTypes: &contentTypes` list shared by both extensions.
    static var supportedContentTypes: Set<String> {
        let lines = projectYML.components(separatedBy: "\n")
        guard let start = lines.firstIndex(where: { $0.contains("QLSupportedContentTypes: &contentTypes") }) else { return [] }
        return Set(lines[(start + 1)...]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .prefix { $0.hasPrefix("- ") }
            .map { String($0.dropFirst(2)) })
    }

    static var importedTypes: Set<String> {
        let regex = /UTTypeIdentifier: ([\w.-]+)/
        return Set(projectYML.matches(of: regex).map { String($0.1) })
    }

    @Test func registryMatchesInfoPlist() {
        #expect(!Self.supportedContentTypes.isEmpty)
        #expect(FormatRegistry.contentTypes == Self.supportedContentTypes)
    }

    @Test func importedTypesAreHandled() {
        #expect(!Self.importedTypes.isEmpty)
        #expect(Self.importedTypes.isSubset(of: FormatRegistry.contentTypes))
    }

    @Test func findsRendererByExactType() {
        #expect(FormatRegistry.renderer(for: .swiftSource) is SourceCodeRenderer)
        #expect(FormatRegistry.renderer(for: .assemblyLanguageSource) is SourceCodeRenderer)
        // Conforms to public.source-code but is not listed.
        #expect(FormatRegistry.renderer(for: .appleScript) == nil)
        #expect(FormatRegistry.renderer(for: .png) == nil)
    }
}

@Suite struct SourceCodeRendererTests {
    let fixtures = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appending(path: "Fixtures")

    @Test func previewHighlightsAndNumbersLines() throws {
        var settings = Settings()
        settings.lineNumbers = true
        let doc = try SourceCodeRenderer().preview(
            of: fixtures.appending(path: "sample.swift"), context: RenderContext(settings: settings, contentType: .swiftSource))
        #expect(doc.html.contains("data-language=\"swift\""))
        #expect(doc.html.contains("<span class=\"line\">"))
        #expect(doc.html.contains("hljs-keyword"))
    }

    @Test func thumbnailIsHighlightedText() throws {
        let s = try SourceCodeRenderer().thumbnail(
            of: fixtures.appending(path: "sample.py"), context: RenderContext(settings: Settings(), contentType: .pythonScript))
        #expect(s.string.hasPrefix("from dataclasses import dataclass"))
    }
}
