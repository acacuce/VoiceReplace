//
//  PresetSelectorView.swift
//  Voice Changer
//
//  Created by Никита Солдатов on 27.07.2021.
//

import UIKit

final class PresetSelectorView: UIView {

    var tapHandler: ((_ id: String,_ isSelected: Bool) -> Void)?

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 24
        stackView.alignment = .top
        return stackView
    }()

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
        self.layer.cornerRadius = 32
        self.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.layer.masksToBounds = true
    }

    private lazy var blurEffect = UIBlurEffect(style: .dark)
    private lazy var blurredEffectView = UIVisualEffectView(effect: blurEffect)
    private var previousSelected: PresetButton?

    private func addSubviews() {
        addSubview(blurredEffectView)
        blurredEffectView.contentView.addSubview(scrollView)
        scrollView.addSubview(stackView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        blurredEffectView.frame = bounds
    }

    private func makeConstraints() {

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            scrollView.heightAnchor.constraint(equalToConstant: 120),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: 24),
        ])

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
        ])
    }
}

// MARK: - Configurable

extension PresetSelectorView: Configurable {
    struct ViewModel {
        let content: [PresetButton.ViewModel]
    }

    func configure(with viewModel: ViewModel) {
        viewModel.content.forEach { subViewModel in
            let button = PresetButton()
            button.configure(with: subViewModel)
            if subViewModel.isSelected {
                self.previousSelected = button
            }
            button.tapHandler = { [weak self] id, isSelected in
                self?.previousSelected?.isSelected = false
                self?.previousSelected = button
                self?.tapHandler?(id, isSelected)
            }
            stackView.addArrangedSubview(button)
        }
    }
}
