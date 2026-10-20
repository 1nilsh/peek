import Foundation

/// Shared container between the host app and its extensions.
public enum AppGroup {
    /// Injected per target via the `PeekAppGroup` Info.plist key (see project.yml).
    public static let identifier: String =
        Bundle.main.object(forInfoDictionaryKey: "PeekAppGroup") as? String ?? ""

    public static var defaults: UserDefaults? {
        identifier.isEmpty ? nil : UserDefaults(suiteName: identifier)
    }
}
