import AppKit
import SwiftUI

@main struct ExportCampaign {
    @MainActor static func main() throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let source = root.appending(path: "Marketing/Captures")
        let output = root.appending(path: "Marketing/Exports")
        let slides = [
            Slide(file: "01-timer", title: "Time, on\nyour side.", detail: "A clear countdown. A little peace of mind.", dark: true),
            Slide(file: "02-directions", title: "Your spot.\nRemembered.", detail: "Walking directions, all the way back.", dark: false),
            Slide(file: "03-setup", title: "Set your stay.\nEnjoy your day.", detail: "Your time, your place, your little details.", dark: false),
            Slide(file: "04-history", title: "Every stay.\nClose at hand.", detail: "Saved locations, notes, and parking history.", dark: true),
            Slide(file: "05-insights", title: "A rhythm\nof your own.", detail: "Get to know your parking patterns.", dark: false)
        ]
        for family in ["duo-outer", "duo-inner"] {
            let size = family == "duo-outer" ? CGSize(width: 1398, height: 2034) : CGSize(width: 2853, height: 2007)
            let folder = output.appending(path: family)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            for (index, slide) in slides.enumerated() {
                let image = try loadImage(source.appending(path: "\(family)/\(slide.file).png"))
                try render(ScreenshotPoster(slide: slide, capture: image, index: index + 1, size: size), size: size, to: folder.appending(path: "\(slide.file).png"))
            }
            let timer = try loadImage(source.appending(path: "\(family)/01-timer.png"))
            let directions = try loadImage(source.appending(path: "\(family)/02-directions.png"))
            try render(ScreenshotPoster(slide: Slide(file: "ppo-time-first", title: "More city.\nLess clock.", detail: "Keep your return time in view.", dark: true), capture: timer, index: 1, size: size), size: size, to: folder.appending(path: "ppo-time-first.png"))
            try render(ScreenshotPoster(slide: Slide(file: "ppo-spot-first", title: "Your way back,\nbeautifully simple.", detail: "A saved spot. Walking directions. One less worry.", dark: true), capture: directions, index: 1, size: size), size: size, to: folder.appending(path: "ppo-spot-first.png"))
        }
        let previewFrames = output.appending(path: "preview-frames")
        try FileManager.default.createDirectory(at: previewFrames, withIntermediateDirectories: true)
        for (file, title) in [("03-setup", "Set your stay."), ("01-timer", "Keep time in sight."), ("02-directions", "Find your way back."), ("04-history", "Remember every stop."), ("05-insights", "Know your rhythm.")] {
            let capture = try loadImage(source.appending(path: "duo-outer/\(file).png"))
            try render(PreviewFrame(title: title, capture: capture), size: CGSize(width: 886, height: 1920), to: previewFrames.appending(path: "\(file).png"))
        }
        let innerFrames = previewFrames.appending(path: "inner")
        try FileManager.default.createDirectory(at: innerFrames, withIntermediateDirectories: true)
        for (file, title) in [("03-setup", "Set your stay."), ("01-timer", "Keep time in sight."), ("02-directions", "Find your way back."), ("04-history", "Remember every stop."), ("05-insights", "Know your rhythm.")] {
            let capture = try loadImage(source.appending(path: "duo-inner/\(file).png"))
            try render(LandscapePreviewFrame(title: title, capture: capture), size: CGSize(width: 1920, height: 886), to: innerFrames.appending(path: "\(file).png"))
        }
        let art = try loadImage(root.appending(path: "Marketing/Source/spotclock-parking-illustration.png"))
        for (name, size) in [("product-header", CGSize(width: 3840, height: 1646)), ("search-results", CGSize(width: 3840, height: 2560))] {
            try render(BrandPoster(art: art, size: size), size: size, to: output.appending(path: "\(name).png"))
        }
        print("Exported 10 screenshots, 4 optimization variants, header, and search artwork.")
    }

    @MainActor static func render(_ view: some View, size: CGSize, to url: URL) throws {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
        renderer.scale = 1
        renderer.isOpaque = true
        guard let cgImage = renderer.cgImage else { throw ExportError.renderFailed }
        let rep = NSBitmapImageRep(cgImage: cgImage)
        guard let png = rep.representation(using: .png, properties: [:]) else { throw ExportError.renderFailed }
        try png.write(to: url)
    }

    static func loadImage(_ url: URL) throws -> NSImage {
        guard let image = NSImage(contentsOf: url) else { throw ExportError.missingImage(url.path) }
        return image
    }
}

private enum ExportError: Error { case missingImage(String), renderFailed }
private struct Slide {
    var file: String
    var title: String
    var detail: String
    var dark: Bool
}

private let midnight = Color(red: 0.08, green: 0.14, blue: 0.21)
private let ivory = Color(red: 0.965, green: 0.955, blue: 0.933)
private let brass = Color(red: 0.65, green: 0.54, blue: 0.36)

private struct ScreenshotPoster: View {
    var slide: Slide
    var capture: NSImage
    var index: Int
    var size: CGSize
    private var landscape: Bool { size.width > size.height }
    private var foreground: Color { slide.dark ? ivory : midnight }

    var body: some View {
        ZStack {
            (slide.dark ? midnight : ivory)
            if landscape {
                HStack(spacing: 90) {
                    textBlock.frame(width: 760, alignment: .leading)
                    device.frame(maxWidth: .infinity)
                }
                .padding(110)
            } else {
                VStack(alignment: .leading, spacing: 38) {
                    textBlock
                    device.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal, 78).padding(.top, 70).padding(.bottom, 65)
            }
        }
        .foregroundStyle(foreground)
    }

    private var textBlock: some View {
        VStack(alignment: .leading, spacing: landscape ? 54 : 28) {
            HStack(spacing: 14) {
                Image(systemName: "parkingsign").foregroundStyle(brass)
                Text("SPOTCLOCK 2.0").tracking(6)
            }
            .font(.system(size: landscape ? 32 : 29, weight: .medium))
            Text(slide.title)
                .font(.system(size: landscape ? 130 : 112, weight: .regular, design: .serif))
                .tracking(-3)
                .fixedSize(horizontal: false, vertical: true)
            Text(slide.detail)
                .font(.system(size: landscape ? 42 : 37))
                .foregroundStyle(foreground.opacity(0.7))
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
            if landscape {
                Rectangle().fill(brass).frame(width: 80, height: 2).padding(.top, 18)
                Text("PARKING, AT YOUR PACE").font(.system(size: 24)).tracking(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var device: some View {
        Image(nsImage: capture).resizable().aspectRatio(contentMode: .fit)
            .clipShape(.rect(cornerRadius: landscape ? 55 : 58))
            .padding(9)
            .background(midnight.opacity(0.9), in: .rect(cornerRadius: 66))
            .overlay { RoundedRectangle(cornerRadius: 66).strokeBorder(brass.opacity(0.5), lineWidth: 2) }
            .shadow(color: .black.opacity(slide.dark ? 0.28 : 0.13), radius: 35, y: 24)
    }
}

private struct BrandPoster: View {
    var art: NSImage
    var size: CGSize
    private var header: Bool { size.height < 2000 }
    var body: some View {
        ZStack(alignment: .leading) {
            Color(red: 0.97, green: 0.95, blue: 0.92)
            Image(nsImage: art).resizable().aspectRatio(contentMode: .fit)
                .frame(width: header ? 2700 : size.width, height: size.height, alignment: .trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
            VStack(alignment: .leading, spacing: 54) {
                Label("SPOTCLOCK", systemImage: "parkingsign")
                    .font(.system(size: header ? 66 : 62, weight: .medium)).tracking(8)
                Text(header ? "Time, on\nyour side." : "More city.\nLess clock.")
                    .font(.system(size: header ? 148 : 186, design: .serif)).tracking(-4)
                    .lineSpacing(4)
                Text("Your parking,\nbeautifully considered.")
                    .font(.system(size: header ? 52 : 66)).foregroundStyle(midnight.opacity(0.7))
                    .lineSpacing(10)
            }
            .foregroundStyle(midnight)
            .frame(width: header ? 1450 : 1600, alignment: .leading)
            .padding(.leading, 210)
        }
    }
}

private struct PreviewFrame: View {
    var title: String
    var capture: NSImage
    var body: some View {
        ZStack {
            ivory
            VStack(spacing: 36) {
                Text(title).font(.system(size: 58, design: .serif)).foregroundStyle(midnight)
                    .padding(.top, 70)
                Spacer(minLength: 0)
                Image(nsImage: capture).resizable().aspectRatio(contentMode: .fit)
                    .frame(width: 886, height: 1290)
                Spacer(minLength: 0)
                Text("SPOTCLOCK 2.0").font(.system(size: 25, weight: .medium)).tracking(5)
                    .foregroundStyle(midnight).padding(.bottom, 70)
            }
        }
    }
}

private struct LandscapePreviewFrame: View {
    var title: String
    var capture: NSImage
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 40) {
                Text("SPOTCLOCK 2.0").font(.system(size: 26, weight: .medium)).tracking(4)
                Text(title).font(.system(size: 82, design: .serif))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(midnight).padding(50).frame(width: 660, alignment: .leading)
            Image(nsImage: capture).resizable().aspectRatio(contentMode: .fit)
                .frame(width: 1260, height: 886)
        }
        .background(ivory)
    }
}
