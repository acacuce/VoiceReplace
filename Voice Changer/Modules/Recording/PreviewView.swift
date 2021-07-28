//
//  PreviewView.swift
//  Voice Changer
//
//  Created by Никита Солдатов on 26.07.2021.
//

import UIKit
import AVFoundation

class VideoPreviewView: UIView {

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        return layer
    }

    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
