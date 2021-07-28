//
//  RecordingView.swift
//  Voice Changer
//
//  Created by Никита Солдатов on 26.07.2021.
//

import UIKit

final class RecordingView: UIView {
    private(set) lazy var previewView = VideoPreviewView()
    private(set) lazy var recordButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "record"), for: .normal)
        button.setImage(UIImage(named: "recording"), for: .selected)
        return button
    }()

    private(set) lazy var galleryButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "gallery")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.imageView?.tintColor = .white
        return button
    }()

    private lazy var galleryBlurredEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods

    // MARK: - Private Methods

    private func commonInit() {
        addSubviews()
        makeConstraints()
    }

    private func addSubviews() {
        galleryBlurredEffectView.frame = .init(origin: .zero, size: .init(width: 44, height: 44))
        galleryBlurredEffectView.layer.cornerRadius = 12
        galleryBlurredEffectView.layer.masksToBounds = true

        galleryBlurredEffectView.contentView.addSubview(galleryButton)

        addSubview(previewView)
        addSubview(galleryBlurredEffectView)
        addSubview(recordButton)
    }

    private func makeConstraints() {
        previewView.translatesAutoresizingMaskIntoConstraints = false
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        galleryBlurredEffectView.translatesAutoresizingMaskIntoConstraints = false
        galleryButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            previewView.leadingAnchor.constraint(equalTo: leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: trailingAnchor),
            previewView.topAnchor.constraint(equalTo: topAnchor),
            previewView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8),
            recordButton.widthAnchor.constraint(equalToConstant: 64),
            recordButton.heightAnchor.constraint(equalToConstant: 64),
        ])

        NSLayoutConstraint.activate([
            galleryButton.centerYAnchor.constraint(equalTo: galleryButton.superview!.centerYAnchor),
            galleryButton.centerXAnchor.constraint(equalTo: galleryButton.superview!.centerXAnchor),
            galleryButton.heightAnchor.constraint(equalToConstant: 28),
            galleryButton.widthAnchor.constraint(equalToConstant: 28)
        ])


        NSLayoutConstraint.activate([
            galleryBlurredEffectView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            galleryBlurredEffectView.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor),
            galleryBlurredEffectView.heightAnchor.constraint(equalToConstant: 44),
            galleryBlurredEffectView.widthAnchor.constraint(equalToConstant: 44)
        ])
    }
}

// MARK: - Configurable

extension RecordingView: Configurable {
    struct ViewModel {}

    func configure(with viewModel: ViewModel) {}
}
