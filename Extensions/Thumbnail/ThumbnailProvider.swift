import AppKit
import OSLog
import PeekCore
import PeekFormats
import QuickLookThumbnailing

private let log = Logger(subsystem: "bz.nils.peek", category: "thumbnail")

final class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        let url = request.fileURL
        do {
            let type = try url.resourceValues(forKeys: [.contentTypeKey]).contentType
            guard let type, let renderer = FormatRegistry.renderer(for: type) else {
                throw CocoaError(.fileReadUnsupportedScheme)
            }
            let context = RenderContext(settings: .load(), contentType: type)
            let text = try renderer.thumbnail(of: url, context: context)
            let size = ThumbnailPage.contextSize(fitting: request.maximumSize)
            let background = context.theme.light.background.nsColor
            handler(QLThumbnailReply(contextSize: size, currentContextDrawing: {
                ThumbnailPage.draw(text, contextSize: size, background: background)
            }), nil)
        } catch {
            log.error("\(url.lastPathComponent, privacy: .public): \(error, privacy: .public)")
            handler(nil, error)
        }
    }
}
