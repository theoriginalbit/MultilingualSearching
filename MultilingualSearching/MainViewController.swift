//
//  MainViewController.swift
//  RegionPicker
//
//  Created by Joshua Asbury on 29/6/2024.
//

import UIKit

class MainViewController: UIViewController, RegionPickerViewController.Delegate {
    private typealias Copy = L10n.Main
    
    private let label = UILabel()
    
    private var selectedRegionCode: String?
    
    override func loadView() {
        let view = UIView()
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = .systemBackground
        
        label.font = .preferredFont(forTextStyle: .body)
        label.text = Copy.noRegionSelected
        
        var configuration = UIButton.Configuration.filled()
        configuration.buttonSize = .large
        configuration.title = Copy.showRegionPicker
        let button = UIButton(configuration: configuration, primaryAction: UIAction { [unowned self] _ in
            showRegionPicker()
        })
        
        let layoutContainer = UIStackView(arrangedSubviews: [
            label, button,
        ])
        layoutContainer.axis = .vertical
        layoutContainer.alignment = .center
        layoutContainer.spacing = 20
        layoutContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(layoutContainer)
        
        NSLayoutConstraint.activate([
            layoutContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            layoutContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            layoutContainer.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: view.leadingAnchor, multiplier: 1.0),
        ])
        
        self.view = view
    }
    
    private func showRegionPicker() {
        let viewController = RegionPickerViewController(selectedRegionCode: selectedRegionCode)
        viewController.delegate = self
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.prefersLargeTitles = false
        present(navigationController, animated: true)
    }
    
    // MARK: RegionPickerViewController.Delegate
    
    func regionPickerViewController(_ viewController: RegionPickerViewController, didSelectRegionCode regionCode: String) {
        selectedRegionCode = regionCode
        label.text = Locale.current.localizedString(forRegionCode: regionCode)
        dismiss(animated: true)
    }
}
