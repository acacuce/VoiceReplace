//
//  EditorPreviewView.swift
//  Voice Changer
//
//  Created by Никита Солдатов on 26.07.2021.
//

import UIKit
import AVKit
/// A view that displays the visual contents of a player object.
class PlayerView: UIView {
    // Override the property to make AVPlayerLayer the view's backing layer.
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    // The associated player object.
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)
        insetsLayoutMarginsFromSafeArea = false
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
