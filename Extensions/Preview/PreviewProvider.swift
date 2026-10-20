import Foundation
import OSLog
import PeekCore
import PeekFormats
import QuickLookUI
import UniformTypeIdentifiers

private let log = Logger(subsystem: "bz.nils.peek", category: "preview")

final class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let url = request.fileURL
        let type = try url.resourceValues(forKeys: [.contentTypeKey]).contentType
        guard let type, let renderer = FormatRegistry.renderer(for: type) else {
            log.error("no renderer for \(type?.identifier ?? "?", privacy: .public)")
            throw CocoaError(.fileReadUnsupportedScheme)
        }
        let context = RenderContext(settings: .load(), contentType: type)
        let start = ContinuousClock.now
        let document = try renderer.preview(of: url, context: context)
        log.info("rendered \(url.lastPathComponent, privacy: .public) (\(type.identifier, privacy: .public)) in \(ContinuousClock.now - start, privacy: .public)")

        return QLPreviewReply(dataOfContentType: .html, contentSize: document.size) { reply in
            reply.stringEncoding = .utf8
            reply.attachments = document.attachments.mapValues {
                QLPreviewReplyAttachment(data: $0.data, contentType: $0.contentType)
            }
            return Data(document.html.utf8)
        }
    }
}
