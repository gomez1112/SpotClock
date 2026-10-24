import AVFoundation
import AppKit
import Foundation

@available(macOS 27.0, *)
@main struct ExportPreview {
    @MainActor static func main() async throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let isInner = CommandLine.arguments.contains("--inner")
        let width = isInner ? 1920 : 886
        let height = isInner ? 886 : 1920
        let frameDirectory = isInner ? "preview-frames/inner" : "preview-frames"
        let files = ["03-setup", "01-timer", "02-directions", "04-history", "05-insights"]
        let frames: [CGImage] = try files.map { name in
            let url = root.appending(path: "Marketing/Exports/\(frameDirectory)/\(name).png")
            guard let image = NSImage(contentsOf: url), let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                throw PreviewError.missingFrame(name)
            }
            return cg
        }
        let temp = FileManager.default.temporaryDirectory.appending(path: "spotclock-preview-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { do { try FileManager.default.removeItem(at: temp) } catch { print("Temporary preview files: \(temp.path)") } }
        let videoURL = temp.appending(path: "picture.mov")
        let writer = try AVAssetWriter(outputURL: videoURL, fileType: .mov)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width, AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 11_000_000, AVVideoMaxKeyFrameIntervalKey: 30,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264High40,
                AVVideoExpectedSourceFrameRateKey: 30, AVVideoAllowFrameReorderingKey: false
            ],
            AVVideoColorPropertiesKey: [
                AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2
            ]
        ])
        let attributes = CVPixelBufferCreationAttributes(
            pixelFormatType: .init(rawValue: kCVPixelFormatType_32ARGB),
            size: .init(width: width, height: height), compatibility: [.cgImage, .cgBitmapContext])
        let receiver = writer.inputPixelBufferReceiver(for: input, pixelBufferAttributes: attributes)
        try writer.start()
        writer.startSession(atSourceTime: .zero)
        let totalFrames = 600 // 20 seconds, 30 fps; four seconds per real screen.
        for index in 0..<totalFrames {
            guard let pool = receiver.pixelBufferPool else { throw PreviewError.writerFailed }
            let buffer = try pool.makeMutablePixelBuffer()
            try buffer.withUnsafeBuffer { raw in
                CVPixelBufferLockBaseAddress(raw, [])
                defer { CVPixelBufferUnlockBaseAddress(raw, []) }
                guard let context = CGContext(data: CVPixelBufferGetBaseAddress(raw), width: width, height: height,
                    bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(raw),
                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
                    throw PreviewError.writerFailed
                }
            let scene = min(index / 120, frames.count - 1)
            context.draw(frames[scene], in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            let transitionFrame = index % 120
            if scene > 0 && transitionFrame < 10 {
                context.setAlpha(1 - Double(transitionFrame) / 10)
                context.draw(frames[scene - 1], in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            }
            }
            try await receiver.append(CVReadOnlyPixelBuffer(buffer), with: CMTime(value: Int64(index), timescale: 30))
        }
        receiver.finish()
        await writer.finishWriting()
        guard writer.status == .completed else { throw writer.error ?? PreviewError.writerFailed }

        let silenceURL = temp.appending(path: "silence.m4a")
        try writeSilence(seconds: 20, to: silenceURL)
        let composition = AVMutableComposition()
        let video = AVURLAsset(url: videoURL)
        let audio = AVURLAsset(url: silenceURL)
        guard let sourceVideo = try await video.loadTracks(withMediaType: .video).first,
              let sourceAudio = try await audio.loadTracks(withMediaType: .audio).first,
              let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw PreviewError.writerFailed
        }
        let range = CMTimeRange(start: .zero, duration: CMTime(seconds: 20, preferredTimescale: 600))
        try videoTrack.insertTimeRange(range, of: sourceVideo, at: .zero)
        try audioTrack.insertTimeRange(range, of: sourceAudio, at: .zero)
        let destination = root.appending(path: isInner ? "Marketing/Exports/spotclock-2-inner-preview.mp4" : "Marketing/Exports/spotclock-2-preview.mp4")
        if FileManager.default.fileExists(atPath: destination.path) { try FileManager.default.removeItem(at: destination) }
        guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else { throw PreviewError.writerFailed }
        try await export.export(to: destination, as: .mp4)

        let result = AVURLAsset(url: destination)
        guard let track = try await result.loadTracks(withMediaType: .video).first else { throw PreviewError.writerFailed }
        let size = try await track.load(.naturalSize)
        let fps = try await track.load(.nominalFrameRate)
        let duration = try await result.load(.duration).seconds
        let audioCount = try await result.loadTracks(withMediaType: .audio).count
        let minimumFrame = try await track.load(.minFrameDuration)
        guard size == CGSize(width: width, height: height),
              CMTimeCompare(minimumFrame, CMTime(value: 1, timescale: 30)) >= 0,
              duration >= 15, duration <= 30, audioCount > 0 else {
            throw PreviewError.invalidExport
        }
        print("Verified preview: \(Int(size.width))×\(Int(size.height)), \(duration)s, \(fps) fps, \(audioCount) audio track.")
    }

    static func writeSilence(seconds: Int, to url: URL) throws {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48_000, channels: 2, interleaved: false),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(48_000 * seconds)),
              let channels = buffer.floatChannelData else { throw PreviewError.writerFailed }
        buffer.frameLength = buffer.frameCapacity
        for channel in 0..<2 { channels[channel].initialize(repeating: 0, count: Int(buffer.frameLength)) }
        let file = try AVAudioFile(forWriting: url, settings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 48_000,
            AVNumberOfChannelsKey: 2, AVEncoderBitRateKey: 256_000
        ], commonFormat: .pcmFormatFloat32, interleaved: false)
        try file.write(from: buffer)
    }

}

private enum PreviewError: Error { case missingFrame(String), writerFailed, invalidExport }
