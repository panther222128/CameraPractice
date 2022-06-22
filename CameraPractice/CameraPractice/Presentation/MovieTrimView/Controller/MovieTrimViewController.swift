//
//  MovieTrimViewController.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/21.
//

import UIKit
import SnapKit

class MovieTrimViewController: UIViewController {

    private var viewModel: MovieTrimViewModel!
    
    private let trimExecuteButton = UIButton()
    private let startTimeTextField = UITextField()
    private let endTimeTextField = UITextField()
    private var startTime = Float()
    private var endTime = Float()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.addSubviews()
        self.configureLayout()
        self.configureTextFields()
        self.configureTrimExecuteButton()
        self.startTimeTextField.delegate = self
        self.endTimeTextField.delegate = self
        self.requestAsset()
    }

    static func create(with viewModel: MovieTrimViewModel) -> MovieTrimViewController {
        let viewController = MovieTrimViewController()
        viewController.viewModel = viewModel
        return viewController
    }
    
}

extension MovieTrimViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        DispatchQueue.main.async {
            guard let startTimeText = self.startTimeTextField.text else { return }
            self.startTime = (startTimeText as NSString).floatValue
            guard let endTimeText = self.endTimeTextField.text else { return }
            self.endTime = (endTimeText as NSString).floatValue
        }
    }
    
}

// MARK: - Add subviews and layout

extension MovieTrimViewController {
    
    private func addSubviews() {
        self.view.addSubview(self.startTimeTextField)
        self.view.addSubview(self.endTimeTextField)
        self.view.addSubview(self.trimExecuteButton)
    }
    
    private func configureLayout() {
        self.startTimeTextField.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(self.view.snp.top).offset(120)
        }
        self.endTimeTextField.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(self.view.snp.bottom).offset(-60)
        }
        self.trimExecuteButton.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    private func showTrimSuccessAlert() {
        
    }
    
    private func showErrorAlert() {
        
    }
    
}

// MARK: - TextField

extension MovieTrimViewController {
     
    private func configureTextFields() {
        self.startTimeTextField.layer.borderColor = UIColor.systemPink.cgColor
        self.endTimeTextField.layer.borderColor = UIColor.systemPink.cgColor
        self.startTimeTextField.backgroundColor = .white
        self.endTimeTextField.backgroundColor = .white
        self.startTimeTextField.placeholder = "Start Time"
        self.endTimeTextField.placeholder = "End Time"
        self.startTimeTextField.borderStyle = .roundedRect
        self.endTimeTextField.borderStyle = .roundedRect
    }
    
}

// MARK: - Button

extension MovieTrimViewController {
    
    private func requestAsset() {
        self.viewModel.fetchAssetCollection()
    }
    
    private func configureTrimExecuteButton() {
        self.trimExecuteButton.setTitle("Trim", for: .normal)
        self.trimExecuteButton.setTitleColor(.systemPink, for: .normal)
        self.trimExecuteButton.addTarget(self, action: #selector(self.trimAsset), for: .touchUpInside)
    }
    
    @objc func trimAsset() {
        self.viewModel.didTrimMovie(from: self.startTime, to: self.endTime) { result in
            switch result {
            case .success(let asset):
                self.showTrimSuccessAlert()
            case .failure(let error):
                self.showErrorAlert()
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
}
