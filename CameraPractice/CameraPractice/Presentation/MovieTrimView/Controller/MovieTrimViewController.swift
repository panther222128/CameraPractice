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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.addSubviews()
        self.configureLayout()
        self.configureTextFields()
        self.configureTrimExecuteButton()
        self.startTimeTextField.delegate = self
        self.endTimeTextField.delegate = self
    }

    static func create(with viewModel: MovieTrimViewModel) -> MovieTrimViewController {
        let viewController = MovieTrimViewController()
        viewController.viewModel = viewModel
        return viewController
    }
    
}

extension MovieTrimViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
    }
    
}

// Add subviews and layout

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
    
    private func configureTrimExecuteButton() {
        self.trimExecuteButton.setTitle("Trim", for: .normal)
        self.trimExecuteButton.setTitleColor(.systemPink, for: .normal)
    }
    
}
