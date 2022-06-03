//
//  CameraViewController.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import UIKit
import AVFoundation
import SnapKit

final class CameraViewController: UIViewController {

    private var viewModel: CameraViewModel!
    private let previewView = PreviewView()
    private let takePhotoButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel.checkIsAuthorized()
        self.addSubviews()
        self.configureLayout()
        self.configureTakePhotoButton()
        self.bind()
    }
    
    private func bind() {
        self.viewModel.isAuthorized.bind { [weak self] isAuthorized in
            guard let self = self else { return }
            guard let isAuthorized = isAuthorized else { return }
            if isAuthorized {
                DispatchQueue.main.async {
                    self.viewModel.didPressTakePhotoButton(previewView: self.previewView)
                }
            } else {
                self.presentAuthorizationAlert()
            }
        }
    }
    
    static func create(with viewModel: CameraViewModel) -> CameraViewController {
        let viewController = CameraViewController()
        viewController.viewModel = viewModel
        return viewController
    }
    
    private func presentAuthorizationAlert() {
        DispatchQueue.main.async {
            let authorizationAlert = UIAlertController(title: "카메라 접근 권한", message: "접근 권한을 허용하지 않으면 카메라를 사용할 수 없습니다.", preferredStyle: UIAlertController.Style.alert)
            let addAuthorizationAlertAction = UIAlertAction(title: "OK", style: .default)
            authorizationAlert.addAction(addAuthorizationAlertAction)
            self.present(authorizationAlert, animated: true, completion: nil)
        }
    }
    
}

// MARK: - Configure views

extension CameraViewController {
    
    private func addSubviews() {
        self.view.addSubview(self.previewView)
        self.view.addSubview(self.takePhotoButton)
    }
    
    private func configureLayout() {
        self.previewView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        self.takePhotoButton.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.equalTo(self.previewView.snp.bottom).offset(-60)
        }
    }
    
    private func configureTakePhotoButton() {
        self.takePhotoButton.backgroundColor = .red
    }
    
}

