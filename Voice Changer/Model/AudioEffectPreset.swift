//
//  AudioEffectPreset.swift
//  Voice Changer
//
//  Created by Никита Солдатов on 28.07.2021.
//

import AVFoundation
import Foundation

struct AudioEffectPresset {
    struct Distortion {
        let preset: AVAudioUnitDistortionPreset?
        let wetDryMix: Float
        let preGain: Float
    }

    struct Pitch {
        let pitch: Float
        let overlap: Float
    }

    struct Reverb {
        let preset: AVAudioUnitReverbPreset?
        let wetDryMix: Float
    }

    let id: String
    let name: String
    let distortion: Distortion
    let pitch: Pitch
    let reverb: Reverb

    static let none = AudioEffectPresset(
        id: "empty",
        name: "Без\nэфектов",
        distortion: .init(
            preset: nil,
            wetDryMix: 0,
            preGain: 0
        ),
        pitch: .init(
            pitch: 1,
            overlap: 0
        ),
        reverb: Reverb(
            preset: nil,
            wetDryMix: 0
        )
    )
}
