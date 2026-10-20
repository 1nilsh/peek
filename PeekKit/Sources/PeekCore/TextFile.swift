import Foundation

/// The decoded head of a text file, cut at a line boundary when it exceeds a byte limit.
public struct TextFile: Sendable {
    public let text: String
    public let byteCount: Int
    public let isTruncated: Bool

    public static func read(_ url: URL, limit: Int) throws -> TextFile {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var data = try handle.read(upToCount: limit + 1) ?? Data()
        let isTruncated = data.count > limit
        if isTruncated {
            data = data.prefix(limit)
            if let newline = data.lastIndex(of: UInt8(ascii: "\n")) { data = data[..<newline] }
        }
        let byteCount = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? data.count
        return TextFile(text: decode(data), byteCount: byteCount, isTruncated: isTruncated)
    }

    static func decode(_ data: Data) -> String {
        if let s = String(data: data, encoding: .utf8) {
            return s.hasPrefix("\u{FEFF}") ? String(s.dropFirst()) : s
        }
        var converted: NSString?
        let encoding = NSString.stringEncoding(for: data, encodingOptions: nil, convertedString: &converted, usedLossyConversion: nil)
        if encoding != 0, let converted { return converted as String }
        return String(decoding: data, as: UTF8.self)
    }

    /// Notice for truncated previews, e.g. "Showing 195 KB of 1.0 MB."
    public var truncationNotice: String? {
        guard isTruncated else { return nil }
        let f = ByteCountFormatter()
        return "Showing \(f.string(fromByteCount: Int64(text.utf8.count))) of \(f.string(fromByteCount: Int64(byteCount)))."
    }
}
