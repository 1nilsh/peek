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
        s.save(to: d)
        #expect(Settings.load(from: d) == s)
    }
}

@Suite struct HTMLPageTests {
    @Test func blocksScriptsAndRemoteImagesByDefault() {
        let html = HTMLPage.render(body: "", context: RenderContext(settings: Settings(), contentType: nil))
        #expect(html.contains("default-src 'none'"))
        #expect(html.contains("img-src cid: data:\""))
    }
}
