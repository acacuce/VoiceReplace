//
//  AudioPressetFactory.swift
//  Voice Changer
//
//  Created by Никита Солдатов on 27.07.2021.
//

import Foundation
import UIKit

final class AudioPressetFactory {
    func availablePresets() -> [AudioEffectPresset] {
        let monster = AudioEffectPresset(
            id: "alien",
            name: "Монстр\nпришелец",
            distortion: .init(
                preset: .speechCosmicInterference,
                wetDryMix: 90,
                preGain: .zero
            ),
            pitch: .init(
                pitch: 100,
                overlap: 6
            ),
            reverb: .init(
                preset: nil,
                wetDryMix: .zero
            )
        )

        let man = AudioEffectPresset(
            id: "man",
            name: "Мальчик",
            distortion: .init(
                preset: nil,
                wetDryMix: .zero,
                preGain: .zero
            ),
            pitch: .init(
                pitch: -300,
                overlap: 6
            ),
            reverb: .init(
                preset: nil,
                wetDryMix: .zero
            )
        )

        let girl = AudioEffectPresset(
            id: "girl",
            name: "Девочка",
            distortion: .init(
                preset: nil,
                wetDryMix: .zero,
                preGain: .zero
            ),
            pitch: .init(
                pitch: 300,
                overlap: 6
            ),
            reverb: .init(
                preset: nil,
                wetDryMix: .zero
            )
        )

        let cartoon = AudioEffectPresset(
            id: "humster",
            name: "Мультяшный\nперсонаж",
            distortion: .init(
                preset: .speechWaves,
                wetDryMix: 30,
                preGain: .zero
            ),
            pitch: .init(
                pitch: 1000,
                overlap: 6
            ),
            reverb: .init(
                preset: nil,
                wetDryMix: .zero
            )
        )

        let echo = AudioEffectPresset(
            id: "echo",
            name: "Эхо",
            distortion: .init(
                preset: .multiEcho1,
                wetDryMix: 40,
                preGain: .zero
            ),
            pitch: .init(
                pitch: .zero,
                overlap: 6
            ),
            reverb: .init(
                preset: .cathedral,
                wetDryMix: 40
            )
        )

        return [.none, monster, girl, man, cartoon, echo]
    }
}
