//
//  EditorView.swift
//  Voice Changer
//
//  Created by Никита Солдатов on 26.07.2021.
//

import UIKit

final class EditorView: UIView {
    var shareHandler: (() -> Void)?
    var closeHandler: (() -> Void)?
    var tapHandler: ((_ id: String,_ isSelected: Bool) -> Void)? {
        didSet {
            self.presetSelectorView.tapHandler = tapHandler
        }
    }

    private(set) lazy var playerView = PlayerView()
    private(set) lazy var presetSelectorView = PresetSelectorView()
    private(set) lazy var shareButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "share")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.imageView?.tintColor = .white
        button.addTarget(self, action: #selector(share), for: .touchUpInside)
        return button
    }()

    private(set) lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "close")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.imageView?.tintColor = .white
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        return button
    }()

    private lazy var shareBlurredEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private lazy var closeBlurredEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private(set) lazy var activityIndicator = UIActivityIndicatorView(style: .white)


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
        shareBlurredEffectView.frame = .init(origin: .zero, size: .init(width: 38, height: 38))
        shareBlurredEffectView.layer.cornerRadius = 19
        shareBlurredEffectView.layer.masksToBounds = true

        shareBlurredEffectView.contentView.addSubview(shareButton)
        shareBlurredEffectView.contentView.addSubview(activityIndicator)

        closeBlurredEffectView.frame = .init(origin: .zero, size: .init(width: 38, height: 38))
        closeBlurredEffectView.layer.cornerRadius = 19
        closeBlurredEffectView.layer.masksToBounds = true

        closeBlurredEffectView.contentView.addSubview(closeButton)

        addSubview(playerView)
        addSubview(presetSelectorView)
        addSubview(shareBlurredEffectView)
        addSubview(closeBlurredEffectView)
    }

    private func makeConstraints() {
        playerView.translatesAutoresizingMaskIntoConstraints = false
        presetSelectorView.translatesAutoresizingMaskIntoConstraints = false
        shareBlurredEffectView.translatesAutoresizingMaskIntoConstraints = false
        closeBlurredEffectView.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            playerView.topAnchor.constraint(equalTo: topAnchor),
            playerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            shareButton.centerYAnchor.constraint(equalTo: shareButton.superview!.centerYAnchor),
            shareButton.centerXAnchor.constraint(equalTo: shareButton.superview!.centerXAnchor),
            shareButton.heightAnchor.constraint(equalToConstant: 24),
            shareButton.widthAnchor.constraint(equalToConstant: 24)
        ])

        NSLayoutConstraint.activate([
            closeButton.centerYAnchor.constraint(equalTo: closeButton.superview!.centerYAnchor),
            closeButton.centerXAnchor.constraint(equalTo: closeButton.superview!.centerXAnchor),
            closeButton.heightAnchor.constraint(equalToConstant: 24),
            closeButton.widthAnchor.constraint(equalToConstant: 24)
        ])

        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: shareButton.superview!.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: shareButton.superview!.centerXAnchor),
            activityIndicator.heightAnchor.constraint(equalToConstant: 24),
            activityIndicator.widthAnchor.constraint(equalToConstant: 24)
        ])


        NSLayoutConstraint.activate([
            shareBlurredEffectView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            shareBlurredEffectView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 24),
            shareBlurredEffectView.heightAnchor.constraint(equalToConstant: 38),
            shareBlurredEffectView.widthAnchor.constraint(equalToConstant: 38)
        ])

        NSLayoutConstraint.activate([
            closeBlurredEffectView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            closeBlurredEffectView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 24),
            closeBlurredEffectView.heightAnchor.constraint(equalToConstant: 38),
            closeBlurredEffectView.widthAnchor.constraint(equalToConstant: 38)
        ])



        NSLayoutConstraint.activate([
            presetSelectorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            presetSelectorView.trailingAnchor.constraint(equalTo: trailingAnchor),
            presetSelectorView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @objc private func share() {
        activityIndicator.startAnimating()
        shareButton.isHidden = true
        shareHandler?()
    }

    @objc private func close() {
        closeHandler?()
    }

    func enableSharing() {
        activityIndicator.stopAnimating()
        shareButton.isHidden = false
    }
}

// MARK: - Configurable

extension EditorView: Configurable {
    struct ViewModel {
        let presetsList: PresetSelectorView.ViewModel
    }

    func configure(with viewModel: ViewModel) {
        presetSelectorView.configure(with: viewModel.presetsList)
    }
}
