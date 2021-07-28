//
//  AudioPlayer.swift
//  Voice Changer
//
//  Created by Никита Солдатов on 27.07.2021.
//

import Foundation
import AVFoundation

final class AudioPlayer {
    private let audioFile: AVAudioFile
    private(set) var audioPlayerNode = AVAudioPlayerNode()
    private(set) var audioEngine = AVAudioEngine()
    private let distortionPreprocessor = AVAudioUnitDistortion()
    private let pitchPreprocessor = AVAudioUnitTimePitch()
    private let reverbPreprocessor = AVAudioUnitReverb()
    private var isPaused = false

    init(audioFile: AVAudioFile) {
        self.audioFile = audioFile
    }

    func play() {
        if isPaused {
            isPaused = false
            try? audioEngine.start()
            audioPlayerNode.play()
            return
        }
        prepareAudioEngine()
        applyPreset(.none)
        let audioFormat = audioFile.processingFormat
        let audioFrameCount = UInt32(audioFile.length)
        guard let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)  else{ return }
        do{
            try audioFile.read(into: audioFileBuffer)
        } catch{
            print("over")
        }
        do {
            try audioEngine.start()
        } catch let error as NSError {
            print("Error starting audio engine.\n\(error.localizedDescription)")
        }

        audioPlayerNode.play()
        audioPlayerNode.scheduleBuffer(audioFileBuffer, at: nil, options:AVAudioPlayerNodeBufferOptions.loops)
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

    func stop() {
        audioPlayerNode.stop()
        audioEngine.stop()
        audioEngine.reset()
    }

    func pause() {
        isPaused = true
        audioPlayerNode.pause()
        audioEngine.pause()
    }

    private func prepareAudioEngine() {
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
}
