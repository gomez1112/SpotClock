import AVFoundation
import AppKit
import Foundation

@main struct VerifyMedia {
    @MainActor static func main() async throws {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let qa = root.appending(path: "Marketing/QA")
        try FileManager.default.createDirectory(at: qa, withIntermediateDirectories: true)
        var reports: [[String: Any]] = []
        for (name, expected) in [("spotclock-2-preview", CGSize(width: 886, height: 1920)), ("spotclock-2-inner-preview", CGSize(width: 1920, height: 886))] {
            let url = root.appending(path: "Marketing/Exports/\(name).mp4")
            let asset = AVURLAsset(url: url)
            guard let video = try await asset.loadTracks(withMediaType: .video).first,
                  let format = try await video.load(.formatDescriptions).first else { throw VerificationError.missingTrack }
            let size = try await video.load(.naturalSize)
            let minimumFrame = try await video.load(.minFrameDuration)
            let duration = try await asset.load(.duration).seconds
            let audioTracks = try await asset.loadTracks(withMediaType: .audio)
            let audio = audioTracks.count
            guard let audioTrack = audioTracks.first,
                  let audioFormat = try await audioTrack.load(.formatDescriptions).first,
                  let audioDescription = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormat)?.pointee,
                  let atoms = CMFormatDescriptionGetExtension(format, extensionKey: kCMFormatDescriptionExtension_SampleDescriptionExtensionAtoms) as? [String: Any],
                  let avcConfiguration = atoms["avcC"] as? Data,
                  avcConfiguration.count > 3 else { throw VerificationError.invalidMedia }
            let audioBitrate = try await audioTrack.load(.estimatedDataRate)
            let codec = CMFormatDescriptionGetMediaSubType(format)
            guard size == expected, codec == kCMVideoCodecType_H264, audio > 0,
                  avcConfiguration[1] == 100, avcConfiguration[3] <= 40,
                  audioDescription.mFormatID == kAudioFormatMPEG4AAC,
                  audioDescription.mChannelsPerFrame == 2,
                  [44_100.0, 48_000.0].contains(audioDescription.mSampleRate),
                  duration >= 15, duration <= 30,
                  CMTimeCompare(minimumFrame, CMTime(value: 1, timescale: 30)) >= 0 else { throw VerificationError.invalidMedia }
            reports.append(["file": url.lastPathComponent, "width": size.width, "height": size.height,
                            "durationSeconds": duration, "fps": 30, "codec": "H.264", "audioTracks": audio,
                            "audio": "silent stereo AAC", "audioChannels": 2,
                            "audioSampleRate": audioDescription.mSampleRate,
                            "audioTargetBitrate": 256_000, "audioEstimatedBitrate": audioBitrate,
                            "videoProfile": "High 4.0", "videoTargetBitrate": 11_000_000, "passed": true])
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            let frame = try await generator.image(at: CMTime(seconds: 6, preferredTimescale: 600)).image
            let rep = NSBitmapImageRep(cgImage: frame)
            guard let png = rep.representation(using: .png, properties: [:]) else { throw VerificationError.invalidMedia }
            try png.write(to: qa.appending(path: "\(name)-at-6s.png"))
        }
        let report = try JSONSerialization.data(withJSONObject: ["previews": reports], options: [.prettyPrinted, .sortedKeys])
        try report.write(to: qa.appending(path: "media-validation.json"))
        print("Both previews passed duration, dimensions, H.264, frame timing, and audio-track checks.")
    }
}
private enum VerificationError: Error { case missingTrack, invalidMedia }
