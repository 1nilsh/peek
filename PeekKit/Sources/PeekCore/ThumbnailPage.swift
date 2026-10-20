import AppKit

/// Draws thumbnail text onto a portrait page. Drawing happens at `size` and is scaled to the requested size.
public enum ThumbnailPage {
    public static let size = CGSize(width: 600, height: 776)
    public static let inset: CGFloat = 28
    public static var font: NSFont { .monospacedSystemFont(ofSize: 15, weight: .regular) }

    public static func contextSize(fitting maximum: CGSize) -> CGSize {
        let scale = min(maximum.width / size.width, maximum.height / size.height)
        return CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
    }

    /// Draws into the current `NSGraphicsContext`. Returns false if there is none.
    public static func draw(_ text: NSAttributedString, contextSize: CGSize, background: NSColor = .white) -> Bool {
        guard let cg = NSGraphicsContext.current?.cgContext else { return false }
        cg.scaleBy(x: contextSize.width / size.width, y: contextSize.height / size.height)
        background.setFill()
        CGRect(origin: .zero, size: size).fill()
        text.draw(with: CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset),
                  options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])
        return true
    }

    /// First `maxLines` lines of `text`; enough to fill the page without laying out the whole file.
    public static func head(of text: String, maxLines: Int = 60) -> String {
        text.split(separator: "\n", maxSplits: maxLines, omittingEmptySubsequences: false)
            .prefix(maxLines).joined(separator: "\n")
    }
}
