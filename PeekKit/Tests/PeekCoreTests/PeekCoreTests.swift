import Foundation
import Testing
@testable import PeekCore

@Suite struct TextFileTests {
    func write(_ data: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "peek-\(UUID().uuidString).txt")
        try data.write(to: url)
        return url
    }

    @Test func readsSmallFileCompletely() throws {
        let url = try write(Data("a\nb\n".utf8))
        let f = try TextFile.read(url, limit: 100)
        #expect(f.text == "a\nb\n")
        #expect(!f.isTruncated)
        #expect(f.truncationNotice == nil)
    }

    @Test func truncatesAtLastNewline() throws {
        let url = try write(Data("line1\nline2\nline3".utf8))
        let f = try TextFile.read(url, limit: 14)
        #expect(f.text == "line1\nline2")
        #expect(f.isTruncated)
        #expect(f.byteCount == 17)
    }

    @Test func describesTruncation() throws {
        let url = try write(Data(String(repeating: "x\n", count: 2_000).utf8))
        let notice = try #require(try TextFile.read(url, limit: 1_000).truncationNotice)
        #expect(notice.hasPrefix("Showing "))
    }

    @Test func stripsUTF8BOM() throws {
        let url = try write(Data([0xEF, 0xBB, 0xBF]) + Data("x".utf8))
        #expect(try TextFile.read(url, limit: 100).text == "x")
    }

    @Test func decodesNonUTF8() throws {
        let url = try write("Grüße".data(using: .isoLatin1)!)
        #expect(try TextFile.read(url, limit: 100).text == "Grüße")
    }
}

@Suite struct SettingsTests {
    @Test func defaultsWhenEmpty() {
        let d = UserDefaults(suiteName: "peek-test-\(UUID().uuidString)")!
        #expect(Settings.load(from: d) == Settings())
    }

    @Test func readsStoredValues() {
        let d = UserDefaults(suiteName: "peek-test-\(UUID().uuidString)")!
        d.set("github", forKey: Settings.Key.themeID.rawValue)
        d.set(false, forKey: Settings.Key.wordWrap.rawValue)
        d.set(16.0, forKey: Settings.Key.fontSize.rawValue)
        let s = Settings.load(from: d)
        #expect(s.themeID == "github")
        #expect(s.wordWrap == false)
        #expect(s.fontSize == 16)
    }

    @Test func saveRoundTrips() {
        let d = UserDefaults(suiteName: "peek-test-\(UUID().uuidString)")!
        var s = Settings()
        s.themeID = "github"
        s.lineNumbers = true
        s.tabWidth = 2
        s.rawHTML = .escape
        s.appearance = .dark
        s.darkThumbnails = true
        s.save(to: d)
        #expect(Settings.load(from: d) == s)
    }
}

@Suite struct ThumbnailPageTests {
    @Test func keepsPortraitAspectWithinMaximum() {
        let size = ThumbnailPage.contextSize(fitting: CGSize(width: 256, height: 256))
        #expect(size.height == 256)
        #expect(size.width < size.height)
    }

    @Test func limitsLines() {
        let text = (1...100).map(String.init).joined(separator: "\n")
        #expect(ThumbnailPage.head(of: text, maxLines: 3) == "1\n2\n3")
        #expect(ThumbnailPage.head(of: "a\nb", maxLines: 3) == "a\nb")
    }
}

@Suite struct RenderContextTests {
    @Test func thumbnailPaletteFollowsSetting() {
        var s = Settings()
        #expect(RenderContext(settings: s, contentType: nil).thumbnailPalette.background == Theme.xcode.light.background)
        s.darkThumbnails = true
        #expect(RenderContext(settings: s, contentType: nil).thumbnailPalette.background == Theme.xcode.dark.background)
    }
}

@Suite struct HTMLPageTests {
    @Test func blocksScriptsAndRemoteImagesByDefault() {
        let html = HTMLPage.render(body: "", context: RenderContext(settings: Settings(), contentType: nil))
        #expect(html.contains("default-src 'none'"))
        #expect(html.contains("img-src cid: data:\""))
    }

    @Test func followsSystemAppearanceByDefault() {
        let html = HTMLPage.render(body: "", context: RenderContext(settings: Settings(), contentType: nil))
        #expect(html.contains("prefers-color-scheme: dark"))
        #expect(html.contains("color-scheme: light dark;"))
    }

    @Test func fixedAppearanceUsesOnlyThatPalette() {
        var s = Settings()
        s.appearance = .dark
        let html = HTMLPage.render(body: "", context: RenderContext(settings: s, contentType: nil))
        #expect(!html.contains("prefers-color-scheme"))
        #expect(html.contains("color-scheme: dark;"))
        #expect(html.contains("--bg: \(Theme.xcode.dark.background.css)"))
        #expect(!html.contains("--bg: \(Theme.xcode.light.background.css)"))
    }
}
