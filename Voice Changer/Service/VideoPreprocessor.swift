//
//  VideoPreprocessor.swift
//  Voice Changer
//
//  Created by Никита Солдатов on 27.07.2021.
//

import Foundation
import AVFoundation

protocol VideoPreprocessorProtocol {
    func processVideo(at url: URL, completion: @escaping Result<EditingVideo, VideoPreprocessorError>.Completion)
}

enum VideoPreprocessorError: Error {
    case exteactAudio
}

final class VideoPreprocessor: VideoPreprocessorProtocol {
    private let processingQueue = DispatchQueue(label: "ru.acacuce.video.preprocess")
    func processVideo(at url: URL, completion: @escaping Result<EditingVideo, VideoPreprocessorError>.Completion) {
        processingQueue.async {
            self.extractAudio(from: url) { audioResult in
                switch audioResult {
                case let .success(audioURL):
                    completion(.success(.init(name: "test", videoURL: url, audioURL: audioURL)))
                case let .failure(error):
                    completion(.failure(error))
                }
            }
        }

    }


    private func extractAudio(from sourceUrl: URL, completion: @escaping Result<URL, VideoPreprocessorError>.Completion) {
        let composition = AVMutableComposition()
        do {
            let asset = AVURLAsset(url: sourceUrl)
            guard let audioAssetTrack = asset.tracks(withMediaType: AVMediaType.audio).first else { return }
            guard let audioCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { return }
            try audioCompositionTrack.insertTimeRange(audioAssetTrack.timeRange, of: audioAssetTrack, at: CMTime.zero)
        } catch {
            print(error)
            completion(.failure(.exteactAudio))
        }

        // Get url for output
        let name = UUID().uuidString
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory() + "\(name).m4a")
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(atPath: outputURL.path)
        }

        // Create an export session
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
            completion(.failure(.exteactAudio))
            return
        }
        exportSession.outputFileType = AVFileType.m4a
        exportSession.outputURL = outputURL

        // Export file
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                print("success")
                completion(.success(outputURL))
            case .failed:
                print("failed \(exportSession.error?.localizedDescription ?? "error nil")")
                completion(.failure(.exteactAudio))
            case .cancelled:
                print("cancelled \(exportSession.error?.localizedDescription ?? "error nil")")
                completion(.failure(.exteactAudio))
            default:
                print("complete")
                completion(.failure(.exteactAudio))
            }
        }
    }
    
}
