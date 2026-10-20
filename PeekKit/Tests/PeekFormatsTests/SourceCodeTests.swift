import Foundation
import PeekCore
import PeekHighlight
import Testing
import UniformTypeIdentifiers
@testable import PeekFormats
@testable import PeekSourceCode

@Suite struct LanguageMapTests {
    /// A language missing from the bundled highlight.js would silently fall back to auto-detection.
    @Test func everyMappedLanguageIsBundled() {
        let languages = Set(LanguageMap.languages.values).union(LanguageMap.extensions.values)
        for language in languages {
            #expect(Highlighter.shared.supports(language), "\(language) not in bundled highlight.js")
        }
    }

    @Test func prefersContentTypeThenExtension() {
        #expect(LanguageMap.language(for: .pythonScript, fileExtension: "txt") == "python")
        #expect(LanguageMap.language(for: .sourceCode, fileExtension: "vue") == "xml")
        #expect(LanguageMap.language(for: .sourceCode, fileExtension: "rs") == "rs")
        #expect(LanguageMap.language(for: .sourceCode, fileExtension: "unknownext") == nil)
        #expect(LanguageMap.language(for: nil, fileExtension: "") == nil)
    }
}

@Suite struct FixtureSmokeTests {
    static let fixtures = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appending(path: "Fixtures")

    static var handledFixtures: [URL] {
        let files = FileManager.default.enumerator(at: fixtures, includingPropertiesForKeys: nil)?.allObjects as? [URL] ?? []
        return files.filter { url in
            UTType(filenameExtension: url.pathExtension).flatMap(FormatRegistry.renderer) != nil
        }.sorted { $0.path < $1.path }
    }

    @Test func coversSeveralFixtures() {
        #expect(Self.handledFixtures.count >= 8)
    }

    @Test(arguments: handledFixtures)
    func rendersPreviewAndThumbnail(_ url: URL) throws {
        let type = try #require(UTType(filenameExtension: url.pathExtension))
        let renderer = try #require(FormatRegistry.renderer(for: type))
        let context = RenderContext(settings: Settings(), contentType: type)
        let document = try renderer.preview(of: url, context: context)
        #expect(document.html.contains("<body>"))
        #expect(try renderer.thumbnail(of: url, context: context).length > 0)
    }
}
