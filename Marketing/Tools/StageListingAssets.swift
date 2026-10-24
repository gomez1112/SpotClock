import Foundation

/// Copies reviewed exports into Bitrig's listing format. This only edits local
/// files; App Store Connect synchronization remains a separate explicit action.
@main struct StageListingAssets {
    static func main() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let exports = root.appending(path: "Marketing/Exports")
        let placements = root.appending(path: "appStoreConnect/appStoreVersion/iOS/localizations/en-US/placements")
        let slides = ["01-timer", "02-directions", "03-setup", "04-history", "05-insights"]
        var screenshots: [[String: String]] = []
        for family in ["duo-outer", "duo-inner"] {
            for slide in slides {
                let name = "\(family)-\(slide).png"
                try copy(exports.appending(path: "\(family)/\(slide).png"), to: placements.appending(path: "app-screenshot/iphone-duo-profile/assets/\(name)"))
                screenshots.append(["fileName": name])
            }
        }
        try manifest(["placements": screenshots], to: placements.appending(path: "app-screenshot/iphone-duo-profile/manifest.json"))
        var previews: [[String: String]] = []
        for name in ["spotclock-2-preview.mp4", "spotclock-2-inner-preview.mp4"] {
            try copy(exports.appending(path: name), to: placements.appending(path: "app-preview/iphone-duo-profile/assets/\(name)"))
            previews.append(["fileName": name, "previewFrameTimeCode": "00:00:06:00"])
        }
        try manifest(["placements": previews], to: placements.appending(path: "app-preview/iphone-duo-profile/manifest.json"))
        for (type, file) in [("product-page-header-asset", "product-header.png"), ("app-store-search-results-asset", "search-results.png")] {
            let group = placements.appending(path: "\(type)/default-profile")
            try copy(exports.appending(path: file), to: group.appending(path: "assets/\(file)"))
            try manifest(["placements": [["fileName": file]]], to: group.appending(path: "manifest.json"))
        }
        print("Staged 10 screenshots, 2 previews, header, and search image. Validate before syncing.")
    }

    static func copy(_ source: URL, to destination: URL) throws {
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: destination.path) { try FileManager.default.removeItem(at: destination) }
        try FileManager.default.copyItem(at: source, to: destination)
    }

    static func manifest(_ value: [String: Any], to url: URL) throws {
        var data = try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys])
        data.append(10)
        try data.write(to: url)
    }
}
