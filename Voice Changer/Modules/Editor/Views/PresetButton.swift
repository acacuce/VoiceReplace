//
//  PresetButton.swift
//  Voice Changer
//
//  Created by Никита Солдатов on 27.07.2021.
//

import UIKit

final class PresetButton: UIControl {
    var tapHandler: ((_ id: String, _ isSelected: Bool) -> Void)?

    private let imageView = UIImageView()
    private let label = UILabel()


    override var intrinsicContentSize: CGSize {
        return CGSize(width: 64, height: UIView.noIntrinsicMetric)
    }

    override var isSelected: Bool {
        didSet {
            imageView.layer.borderColor = UIColor.systemGreen.cgColor
            imageView.layer.borderWidth = isSelected ? 3 : 0
        }
    }

    private(set) var viewModel: ViewModel?

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


        addTarget(self, action: #selector(tap), for: .touchUpInside)

        imageView.layer.cornerRadius = 20
        imageView.backgroundColor = .white
        imageView.contentMode = .center
        label.font = UIFont.preferredFont(forTextStyle: .caption1)
        label.numberOfLines = .zero
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        label.textColor = .white
    }

    private func addSubviews() {
        addSubview(imageView)
        addSubview(label)
    }

    private func makeConstraints() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            imageView.heightAnchor.constraint(equalToConstant: 40),
            imageView.widthAnchor.constraint(equalToConstant: 40),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 10)
        ])

    }

    @objc private func tap() {
        guard isSelected == false else { return }
        isSelected.toggle()
        guard let viewModel = viewModel else { return }
        tapHandler?(viewModel.id, isSelected)
    }
}

// MARK: - Configurable

extension PresetButton: Configurable {
    struct ViewModel {
        let id: String
        let icon: UIImage
        let name: String
        let isSelected: Bool
    }

    func configure(with viewModel: ViewModel) {
        self.viewModel = viewModel
        imageView.image = viewModel.icon
        label.text = viewModel.name
        isSelected = viewModel.isSelected
    }
}
