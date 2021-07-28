//
//  Configurable.swift
//  Voice Changer
//
//  Created by Никита Солдатов on 26.07.2021.
//


/// Небезопасный протокол пригодится для generic collection/table data source
public protocol UnsafeConfigurable {
    func _configure(with viewModel: Any)
}

/// Протокол для описания UIComponent'a, который указывает ассоцированный с ним
/// тип ViewModel и имеет метод для конфигурации с экземпляром ViewModel
/// - Note
///
///  Пример использования:
///
/// ```
/// extension SomeView: Configurable {
///    struct ViewModel {
///      let value: String
///    }
///
///    func configure(with viewModel: ViewModel) {
///       valueLabel.text = viewModel.value
///    }
/// }
/// ```
public protocol Configurable: UnsafeConfigurable {
    associatedtype ViewModel
    /// Конфигурирует view с экземпляром ассоцированного типа ViewModel
    /// - Parameter viewModel: Экземпляр ViewModel содержащий данные
    /// необходимые для отображения view
    func configure(with viewModel: ViewModel)
}

/// Дефолтная реализация
public extension Configurable {
    func _configure(with viewModel: Any) {
        if let concreteViewModel = viewModel as? ViewModel {
            configure(with: concreteViewModel)
        } else {
            assertionFailure(
                """
                    Invalid ViewModel type,
                    expect \(String(reflecting: ViewModel.self))
                    got: \(String(reflecting: viewModel.self))
                """
            )
        }
    }
}
