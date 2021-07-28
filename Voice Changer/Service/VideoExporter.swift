//
//  VideoExporter.swift
//  Voice Changer
//
//  Created by Никита Солдатов on 27.07.2021.
//

import Foundation
import AVFoundation

enum VideoExporterError: Error {
    case audioRender
    case noAudio
    case noVideo
    case videoRender
}

final class VideoExporter {
    private let audioFile: AVAudioFile
    private(set) var audioPlayerNode = AVAudioPlayerNode()
    private(set) var audioEngine = AVAudioEngine()
    private let distortionPreprocessor = AVAudioUnitDistortion()
    private let pitchPreprocessor = AVAudioUnitTimePitch()
    private let reverbPreprocessor = AVAudioUnitReverb()
    private let editedVideo: EditingVideo
    private let processingQueue = DispatchQueue(label: "ru.acacuce.video.export")

    init(editedVideo: EditingVideo) {
        self.audioFile = try! AVAudioFile(forReading: editedVideo.audioURL)
        self.editedVideo = editedVideo
    }

    func exportVideo(with audioPreset: AudioEffectPresset, completion: @escaping Result<URL, VideoExporterError>.Completion) {
        processingQueue.async {
            self.renderAudio(at: self.editedVideo.audioURL, with: audioPreset) { result in
                switch result {
                case let .success(url):
                    self.renderVideo(with: url, completion: completion)
                case .failure:
                    completion(result)
                }
            }
        }
    }

    func renderVideo(with audioURL: URL, completion: @escaping Result<URL, VideoExporterError>.Completion) {
        processingQueue.asyncAfter(deadline: .now() + 0.1) {
            self.mergeVideoAndAudio(
                videoUrl: self.editedVideo.videoURL,
                audioUrl: audioURL,
                shouldFlipHorizontally: false,
                completion: completion
            )
        }
    }

    func mergeVideoAndAudio(
        videoUrl: URL,
        audioUrl: URL,
        shouldFlipHorizontally: Bool = false,
        completion: @escaping Result<URL, VideoExporterError>.Completion)
    {

        let mixComposition = AVMutableComposition()
        var mutableCompositionVideoTrack = [AVMutableCompositionTrack]()
        var mutableCompositionAudioTrack = [AVMutableCompositionTrack]()

        //start merge

        let aVideoAsset = AVAsset(url: videoUrl)
        let aAudioAsset = AVAsset(url: audioUrl)

        guard let compositionAddVideo = mixComposition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            completion(.failure(.noVideo))
            return
        }

        guard let compositionAddAudio = mixComposition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            completion(.failure(.noAudio))
            return
        }


        guard let aVideoAssetTrack: AVAssetTrack = aVideoAsset.tracks(withMediaType: .video).first else {
            completion(.failure(.noAudio))
            return
        }
        guard let aAudioAssetTrack: AVAssetTrack = aAudioAsset.tracks(withMediaType: .audio).first else {
            completion(.failure(.noVideo))
            return
        }

        compositionAddVideo.preferredTransform = aVideoAssetTrack.preferredTransform

        if shouldFlipHorizontally {
            var frontalTransform: CGAffineTransform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            frontalTransform = frontalTransform.translatedBy(x: -aVideoAssetTrack.naturalSize.width, y: 0.0)
            frontalTransform = frontalTransform.translatedBy(x: 0.0, y: -aVideoAssetTrack.naturalSize.width)
            compositionAddVideo.preferredTransform = frontalTransform
        }

        mutableCompositionVideoTrack.append(compositionAddVideo)
        mutableCompositionAudioTrack.append(compositionAddAudio)

        do {
            try mutableCompositionVideoTrack[0].insertTimeRange(
                CMTimeRange(
                    start: .zero,
                    duration: aVideoAssetTrack.timeRange.duration),
                of: aVideoAssetTrack,
                at: .zero
            )

            try mutableCompositionAudioTrack[0].insertTimeRange(
                CMTimeRange(
                    start: .zero,
                    duration: aVideoAssetTrack.timeRange.duration
                ),
                of: aAudioAssetTrack,
                at: .zero
            )


        } catch {
            print(error.localizedDescription)
        }

        let savePathUrl: URL = URL(fileURLWithPath: NSHomeDirectory() + "/Documents/video.mp4")
        do {
            try FileManager.default.removeItem(at: savePathUrl)
        } catch { print(error.localizedDescription) }

        guard let assetExport: AVAssetExportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetPassthrough) else {
            completion(.failure(.videoRender))
            return
        }
        assetExport.outputFileType = .mp4
        assetExport.outputURL = savePathUrl

        assetExport.exportAsynchronously { () -> Void in
            switch assetExport.status {
            case .completed:
                print("success")
                completion(.success(savePathUrl))
            case .failed:
                print("failed \(assetExport.error?.localizedDescription ?? "error nil")")
                completion(.failure(.videoRender))
            case .cancelled:
                print("cancelled \(assetExport.error?.localizedDescription ?? "error nil")")
                completion(.failure(.videoRender))
            default:
                print("complete")
                completion(.failure(.videoRender))
            }
        }

    }

    func applyPreset(_ preset: AudioEffectPresset) {
        if let distortionPreset = preset.distortion.preset {
            distortionPreprocessor.loadFactoryPreset(distortionPreset)
        }

        distortionPreprocessor.preGain = preset.distortion.preGain
        distortionPreprocessor.wetDryMix = preset.distortion.wetDryMix

        if let reverbPreset = preset.reverb.preset {
            reverbPreprocessor.loadFactoryPreset(reverbPreset)
        }

        reverbPreprocessor.wetDryMix = preset.reverb.wetDryMix

        pitchPreprocessor.pitch = preset.pitch.pitch
    }


    private func prepareAudioEngine() {
        // It's needed to stop and reset the audio engine before creating a new one to avoid crashing
        audioEngine.attach(audioPlayerNode)
        var previousNode: AVAudioNode = audioPlayerNode
        let allPreprocessor = [distortionPreprocessor, pitchPreprocessor, reverbPreprocessor]
        for audioUnit in allPreprocessor {
            audioEngine.attach(audioUnit)
            audioEngine.connect(previousNode, to: audioUnit, format: audioFile.processingFormat)
            previousNode = audioUnit
        }

        audioEngine.connect(previousNode, to: audioEngine.mainMixerNode, format: audioFile.processingFormat)
    }

    func renderAudio(at url: URL, with preset: AudioEffectPresset, completion: @escaping Result<URL, VideoExporterError>.Completion) {
        prepareAudioEngine()
        applyPreset(preset)
        audioPlayerNode.scheduleFile(audioFile, at: nil)
        let name = UUID().uuidString
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory() + "\(name).m4a")
        do {
            try audioEngine.enableManualRenderingMode(.offline, format: audioFile.processingFormat, maximumFrameCount: 8192)

            try audioEngine.start()
            audioPlayerNode.play()

            let outputFile: AVAudioFile
            let recordSettings = audioFile.fileFormat.settings
            outputFile = try AVAudioFile(forWriting: outputURL, settings: recordSettings)

            guard let buffer = AVAudioPCMBuffer(pcmFormat: audioEngine.manualRenderingFormat, frameCapacity: audioEngine.manualRenderingMaximumFrameCount) else {
                completion(.failure(.audioRender))
                return
            }

            // Adjust the file size based on the effect rate
            let outputFileLength = Int64(Double(audioFile.length) / 1)

            while audioEngine.manualRenderingSampleTime < outputFileLength {
                let framesToRender = min(buffer.frameCapacity, AVAudioFrameCount(outputFileLength - audioEngine.manualRenderingSampleTime))
                let status = try audioEngine.renderOffline(framesToRender, to: buffer)
                switch status {
                case .success:
                    try outputFile.write(from: buffer)
                case .error:
                    print("Error rendering offline audio")
                    completion(.failure(VideoExporterError.audioRender))
                    return
                default:
                    break
                }
            }
        } catch {
            print(error)
            completion(.failure(.audioRender))
        }
        audioPlayerNode.stop()
        audioEngine.stop()
        audioEngine.disableManualRenderingMode()
        completion(.success(outputURL))

    }
}
