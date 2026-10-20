import AppKit
import QuickLookThumbnailing

/// Phase 0 spike (S5): draws the first lines of a text file on a page.
final class ThumbnailProvider: QLThumbnailProvider {
    private static let pageSize = CGSize(width: 600, height: 776)

    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        let head: String
        do {
            let handle = try FileHandle(forReadingFrom: request.fileURL)
            defer { try? handle.close() }
            let data = try handle.read(upToCount: 8_000) ?? Data()
            head = String(decoding: data, as: UTF8.self)
                .split(separator: "\n", omittingEmptySubsequences: false)
                .prefix(50)
                .joined(separator: "\n")
        } catch {
            handler(nil, error)
            return
        }

        let scale = min(request.maximumSize.width / Self.pageSize.width, request.maximumSize.height / Self.pageSize.height)
        let size = CGSize(width: Self.pageSize.width * scale, height: Self.pageSize.height * scale)

        handler(QLThumbnailReply(contextSize: size, currentContextDrawing: {
            guard let cg = NSGraphicsContext.current?.cgContext else { return false }
            cg.scaleBy(x: scale, y: scale)
            NSColor.white.setFill()
            CGRect(origin: .zero, size: Self.pageSize).fill()
            let text = NSAttributedString(string: head, attributes: [
                .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
                .foregroundColor: NSColor.black,
            ])
            text.draw(in: CGRect(origin: .zero, size: Self.pageSize).insetBy(dx: 24, dy: 24))
            return true
        }), nil)
    }
}
