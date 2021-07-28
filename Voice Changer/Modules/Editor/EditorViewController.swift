//
//  EditorViewController.swift
//  Voice Changer
//
//  Created by Никита Солдатов on 26.07.2021.
//

import UIKit
import AVFoundation

final class EditorViewController: UIViewController {
    private lazy var contentView = EditorView()
    private let editingVideo: EditingVideo
    private lazy var item = AVPlayerItem(url: editingVideo.videoURL)
    private lazy var videoLooper = AVPlayerLooper(player: player, templateItem: item)
    private lazy var player: AVQueuePlayer = {
        return AVQueuePlayer(playerItem: item)
    }()

    private lazy var audioPlayer: AudioPlayer = {
        let url = editingVideo.audioURL
        // file always should exist if passed
        let processor = AudioPlayer(audioFile: try! AVAudioFile(forReading: url))
        return processor
    }()

    private let presets: [AudioEffectPresset]
    private lazy var exporter = VideoExporter(editedVideo: editingVideo)

    init(editingVideo: EditingVideo) {
        self.editingVideo = editingVideo
        self.presets = AudioPressetFactory().availablePresets()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func loadView() {
        self.view = contentView
    }

    private var selectedPresetId: String = "empty"
    override func viewDidLoad() {
        super.viewDidLoad()
        _ = videoLooper.status

        contentView.tapHandler = { [weak self] id, isSelected in
            guard
                let self = self,
                let selectedPreset = self.presets.first(where: { $0.id == id })
            else { return }
            self.selectedPresetId = id
            self.audioPlayer.applyPreset(selectedPreset)
        }

        contentView.closeHandler = { [weak self] in
            self?.audioPlayer.stop()
            self?.player.pause()
            self?.dismiss(animated: true, completion: nil)
        }

        contentView.shareHandler = { [weak self] in
            guard
                let self = self,
                let selectedPreset = self.presets.first(where: { $0.id == self.selectedPresetId })
            else { return }
            self.prepareVideoForExport(with: selectedPreset)
        }

        let presetListViewModel: [PresetButton.ViewModel] = presets.map { preset in
            let image = UIImage(named: preset.id) ?? UIImage()
            let viewModel = PresetButton.ViewModel(
                id: preset.id,
                icon: image,
                name: preset.name,
                isSelected:  preset.id == selectedPresetId
            )
            return viewModel
        }

        contentView.configure(with: .init(presetsList: .init(content: presetListViewModel)))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        contentView.playerView.player = player
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.player.play()
        self.player.isMuted = true
        audioPlayer.play()
    }

    private func prepareVideoForExport(with preset: AudioEffectPresset) {
        self.audioPlayer.pause()
        self.player.pause()
        self.exporter.exportVideo(with: preset) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(url):
                    self.shareVideo(at: url)
                case .failure:
                    self.showShareError()
                }
            }
        }

    }

    private func shareVideo(at url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: [])
        activityViewController.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.audioPlayer.play()
            self?.player.play()
            self?.contentView.enableSharing()
        }
        self.present(activityViewController, animated: true, completion: nil)
    }

    private func showShareError() {
        audioPlayer.play()
        player.play()
        contentView.enableSharing()

        let alertMsg = "Sharing failed"
        let message = NSLocalizedString("Unable to share media", comment: alertMsg)
        let alertController = UIAlertController(title: "Voice Changer", message: message, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                style: .cancel,
                                                handler: nil))

        self.present(alertController, animated: true, completion: nil)
    }

}
