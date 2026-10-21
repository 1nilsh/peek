import AppKit

/// Quick Look keys cached thumbnails on file size and modification date, not on Peek's settings, and has no API
/// to discard them; `qlmanage -r cache` is the only way. Works from the sandbox (verified on macOS 26.6).
enum ThumbnailCache {
    static func reset() async -> Bool {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(filePath: "/usr/bin/qlmanage")
            process.arguments = ["-r", "cache"]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            process.terminationHandler = { continuation.resume(returning: $0.terminationStatus == 0) }
            do {
                try process.run()
            } catch {
                continuation.resume(returning: false)
            }
        }
    }

    /// Finder keeps thumbnails in memory; only a relaunch makes it fetch new ones. `terminate()` sends a quit
    /// Apple event (the sandbox blocks signals), which needs the user's consent to control Finder.
    @MainActor static func relaunchFinder() async -> Bool {
        let id = "com.apple.finder"
        guard let finder = NSRunningApplication.runningApplications(withBundleIdentifier: id).first,
              let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id),
              finder.terminate()
        else { return false }
        let deadline = ContinuousClock.now + .seconds(5)
        while !finder.isTerminated, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(100))
        }
        guard finder.isTerminated else { return false }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        return (try? await NSWorkspace.shared.openApplication(at: url, configuration: configuration)) != nil
    }
}
