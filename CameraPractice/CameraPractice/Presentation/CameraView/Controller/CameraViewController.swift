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

    private var studioConfiguration: StudioConfigurable!
    private var viewModel: CameraViewModel!
    
    private let context = CIContext()
    private let cameraActionButton = UIButton()
    private let cameraScreenView = UIImageView()
    private var pvConverter: UISegmentedControl = {
        let pv = ["Photo", "Video"]
        let pvConverter = UISegmentedControl(items: pv)
        pvConverter.selectedSegmentIndex = 0
        return pvConverter
    }()
    private var cameraConverter: UISegmentedControl = {
        let cameras = ["Default", "Front"]
        let cameraConverter = UISegmentedControl(items: cameras)
        cameraConverter.selectedSegmentIndex = 0
        return cameraConverter
    }()
    private let recordTimerLabel = UILabel()
    
    private var isPhotoMode = true
    private var isRecordOn = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel.didCheckIsDeviceAccessAuthorized()
        self.viewModel.didCheckIsPhotoAlbumAccessAuthorized()
        self.addSubviews()
        self.configureLayout()
        self.configureCameraActionButton()
        self.addCameraConverterTarget()
        self.configureCameraConverter()
        self.addPVConverterTarget()
        self.configurePVConverter()
        self.configureRecordTimerLabel()
        self.bind()
    }
    
    private func bind() {
        self.viewModel.isDeviceAccessAuthorized.bind { [weak self] isAuthorized in
            guard let self = self else { return }
            guard let isAuthorized = isAuthorized else { return }
            if isAuthorized {
                DispatchQueue.main.async {
                    self.studioConfiguration.prepareToUseDevice(at: self.cameraConverter.selectedSegmentIndex, presenter: self)
                }
            } else {
                self.presentDeviceAccessAuthorizationStatusAlert()
            }
        }
        self.viewModel.isPhotoAlbumAccessAuthorized.bind { [weak self] isAuthorized in
            guard let self = self else { return }
            guard let isAuthorized = isAuthorized else { return }
            if isAuthorized {
                DispatchQueue.main.async {
                    
                }
            } else {
                self.presentPhotoAlbumAccessAuthorizationStatusAlert()
            }
        }
    }
    
    static func create(with viewModel: CameraViewModel, with cameraService: StudioConfigurable) -> CameraViewController {
        let viewController = CameraViewController()
        viewController.viewModel = viewModel
        viewController.studioConfiguration = cameraService
        return viewController
    }
    
    private func presentDeviceAccessAuthorizationStatusAlert() {
        DispatchQueue.main.async {
            let authorizationAlert = UIAlertController(title: "카메라 접근 권한", message: "접근 권한을 허용하지 않으면 카메라를 사용할 수 없습니다.", preferredStyle: UIAlertController.Style.alert)
            let addAuthorizationAlertAction = UIAlertAction(title: "OK", style: .default)
            authorizationAlert.addAction(addAuthorizationAlertAction)
            self.present(authorizationAlert, animated: true, completion: nil)
        }
    }
    
    private func presentPhotoAlbumAccessAuthorizationStatusAlert() {
        DispatchQueue.main.async {
            let authorizationAlert = UIAlertController(title: "사진 앨범 접근 권한", message: "접근 권한을 허용하지 않으면 앱의 주요 기능을 사용할 수 없습니다.", preferredStyle: UIAlertController.Style.alert)
            let addAuthorizationAlertAction = UIAlertAction(title: "OK", style: .default)
            authorizationAlert.addAction(addAuthorizationAlertAction)
            self.present(authorizationAlert, animated: true, completion: nil)
        }
    }
    
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
    }
    
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer), let _ = CMSampleBufferGetFormatDescription(sampleBuffer) else { return }
        
        let cameraImage = CIImage(cvImageBuffer: videoPixelBuffer)
        let cg = self.context.createCGImage(cameraImage, from: self.cameraScreenView.frame)!
        
        DispatchQueue.main.async {
            let image = UIImage(cgImage: cg)
            self.cameraScreenView.image = image
        }
    }
    
}



// MARK: - CameraConverter

extension CameraViewController {
    
    private func addCameraConverterTarget() {
        self.cameraConverter.addTarget(self, action: #selector(self.convertCamera), for: .valueChanged)
    }
    
    private func configureCameraConverter() {
        self.cameraConverter.layer.borderWidth = 2
        self.cameraConverter.layer.borderColor = UIColor.systemPink.cgColor
    }
    
    @objc func convertCamera(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            DispatchQueue.main.async {
                self.studioConfiguration.prepareToUseDevice(at: sender.selectedSegmentIndex, presenter: self)
            }
        case 1:
            DispatchQueue.main.async {
                self.studioConfiguration.prepareToUseDevice(at: sender.selectedSegmentIndex, presenter: self)
            }
        default:
            DispatchQueue.main.async {
                self.studioConfiguration.prepareToUseDevice(at: sender.selectedSegmentIndex, presenter: self)
            }
        }
    }
    
}

// MARK: - PVConverter

extension CameraViewController {
    
    private func addPVConverterTarget() {
        self.pvConverter.addTarget(self, action: #selector(self.convertPV), for: .valueChanged)
    }
    
    private func configurePVConverter() {
        self.pvConverter.layer.borderWidth = 2
        self.pvConverter.layer.borderColor = UIColor.systemPink.cgColor
    }
    
    @objc func convertPV(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            DispatchQueue.main.async {
                self.isPhotoMode = true
                if self.isPhotoMode {
                    self.recordTimerLabel.isHidden = true
                    self.convertCameraActionButtonText()
                }
            }
        case 1:
            DispatchQueue.main.async {
                self.isPhotoMode = false
                if !self.isPhotoMode {
                    self.recordTimerLabel.isHidden = false
                    self.convertCameraActionButtonText()
                }
            }
        default:
            DispatchQueue.main.async {
                self.isPhotoMode = true
                if self.isPhotoMode {
                    self.recordTimerLabel.isHidden = true
                    self.convertCameraActionButtonText()
                }
            }
        }
    }
    
}

// MARK: - Button

extension CameraViewController {
    
    private func configureCameraActionButton() {
        self.cameraActionButton.setTitle("Take Photo", for: .normal)
        self.cameraActionButton.addTarget(self, action: #selector(self.pressedCameraActionButton), for: .touchUpInside)
    }
    
    private func convertCameraActionButtonText() {
        if self.isPhotoMode {
            self.cameraActionButton.setTitle("Take Photo", for: .normal)
        } else {
            self.cameraActionButton.setTitle("Record Video", for: .normal)
        }
    }
    
    @objc func pressedCameraActionButton() {
        guard let photoOutput = self.studioConfiguration.photoOutput else { return }
        guard let photoSettings = self.studioConfiguration.photoSettings else { return }
        if self.isPhotoMode {
            self.viewModel.didCapturePhoto(photoSettings: photoSettings, photoOutput: photoOutput)
        } else {
            self.isRecordOn = true
            if self.isRecordOn {
                self.viewModel.didStartRecord(deviceInput: <#T##AVCaptureDeviceInput#>, recorder: <#T##AVCaptureFileOutputRecordingDelegate#>)
            }
        }
        
    }
    
}

// MARK: - Label

extension CameraViewController {
    
    private func configureRecordTimerLabel() {
        self.recordTimerLabel.text = "00:00"
        self.recordTimerLabel.textColor = .white
        self.recordTimerLabel.textAlignment = .center
        self.recordTimerLabel.isHidden = true
    }
    
}

// MARK: - Add subviews and layout

extension CameraViewController {
    
    private func addSubviews() {
        self.view.addSubview(self.cameraScreenView)
        self.view.addSubview(self.cameraActionButton)
        self.view.addSubview(self.cameraConverter)
        self.view.addSubview(self.pvConverter)
        self.view.addSubview(self.recordTimerLabel)
    }
    
    private func configureLayout() {
        self.cameraScreenView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        self.cameraActionButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(self.view.snp.bottom).offset(-60)
        }
        self.cameraConverter.snp.makeConstraints {
            $0.leading.equalTo(self.view.snp.leading).offset(100)
            $0.top.equalTo(self.view.snp.top).offset(80)
            $0.trailing.equalTo(self.view.snp.trailing).offset(-100)
            $0.height.equalTo(38)
        }
        self.pvConverter.snp.makeConstraints {
            $0.leading.equalTo(self.view.snp.leading).offset(100)
            $0.top.equalTo(self.cameraConverter.snp.bottom).offset(4)
            $0.trailing.equalTo(self.view.snp.trailing).offset(-100)
            $0.height.equalTo(38)
        }
        self.recordTimerLabel.snp.makeConstraints {
            $0.centerX.equalTo(self.view.snp.centerX)
            $0.bottom.equalTo(self.cameraActionButton.snp.top).offset(-20)
        }
    }
    
}



