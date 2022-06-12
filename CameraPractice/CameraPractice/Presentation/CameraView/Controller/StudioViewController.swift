//
//  CameraViewController.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import UIKit
import AVFoundation
import SnapKit

protocol DataOutputSampleBufferDelegate: AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate {
    
}

extension StudioViewController: DataOutputSampleBufferDelegate {
    
}

final class StudioViewController: UIViewController {
    
    private var studioConfiguration: StudioConfigurable!
    private var viewModel: StudioViewModel!
    private var recordTimer: RecordTimerConfigurable!
    
    private let context = CIContext()
    private let studioActionButton = UIButton()
    private let captureOutputScreenView = UIImageView()
    private var outputConverter: UISegmentedControl = {
        let outputs = ["Photo", "Movie"]
        let outputConverter = UISegmentedControl(items: outputs)
        outputConverter.selectedSegmentIndex = 0
        return outputConverter
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
        self.viewModel.checkDeviceAccessAuthorizationStatus()
        self.viewModel.checkPhotoAlbumAccessAuthorized()
        self.addSubviews()
        self.configureLayout()
        self.configureStudioActionButton()
        self.addCameraConverterTarget()
        self.configureCameraConverter()
        self.addOutputConverterTarget()
        self.configureOutputConverter()
        self.configureRecordTimerLabel()
        self.configureCaptureOutputScreenView()
        self.bind()
    }
    
    private func bind() {
        self.viewModel.isDeviceAccessAuthorized.bind { [weak self] isAuthorized in
            guard let self = self else { return }
            guard let isAuthorized = isAuthorized else { return }
            if isAuthorized {
                DispatchQueue.main.async {
                    self.studioConfiguration.configureEnvironment(at: 0, presenter: self)
                    self.studioConfiguration.configurePhotoInputOutput(presenter: self)
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
        self.recordTimer.time.bind { [weak self] timeProgressStatus in
            self?.recordTimerLabel.text = timeProgressStatus
        }
    }
    
    static func create(with viewModel: StudioViewModel, with studioConfiguration: StudioConfigurable, with recordTimer: RecordTimerConfigurable) -> StudioViewController {
        let viewController = StudioViewController()
        viewController.viewModel = viewModel
        viewController.studioConfiguration = studioConfiguration
        viewController.recordTimer = recordTimer
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
    
    private func presentServiceErrorAlert(errorMessage: String) {
        DispatchQueue.main.async {
            let authorizationAlert = UIAlertController(title: "오류 발생", message: "\(errorMessage)", preferredStyle: UIAlertController.Style.alert)
            let addAuthorizationAlertAction = UIAlertAction(title: "OK", style: .default)
            authorizationAlert.addAction(addAuthorizationAlertAction)
            self.present(authorizationAlert, animated: true, completion: nil)
        }
    }
    
}

extension StudioViewController: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if (error != nil) {
            self.presentServiceErrorAlert(errorMessage: error!.localizedDescription)
        } else {
            self.viewModel.didSaveRecordedMovie()
        }
    }
    
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension StudioViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer), let _ = CMSampleBufferGetFormatDescription(sampleBuffer) else { return }
        
        let cameraImage = CIImage(cvImageBuffer: videoPixelBuffer)
        let cgImage = self.context.createCGImage(cameraImage, from: self.captureOutputScreenView.frame)!
        
        DispatchQueue.main.async {
            let image = UIImage(cgImage: cgImage)
            self.captureOutputScreenView.image = image
        }
    }
    
}

// MARK: - CameraConverter

extension StudioViewController {
    
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
                self.studioConfiguration.configureEnvironment(at: sender.selectedSegmentIndex, presenter: self)
                if self.isPhotoMode {
                    self.studioConfiguration.configurePhotoInputOutput(presenter: self)
                } else {
                    self.studioConfiguration.configureMovieInputOutput(presenter: self)
                }
            }
        case 1:
            DispatchQueue.main.async {
                self.studioConfiguration.configureEnvironment(at: sender.selectedSegmentIndex, presenter: self)
                if self.isPhotoMode {
                    self.studioConfiguration.configurePhotoInputOutput(presenter: self)
                } else {
                    self.studioConfiguration.configureMovieInputOutput(presenter: self)
                }
            }
        default:
            DispatchQueue.main.async {
                self.studioConfiguration.configureEnvironment(at: sender.selectedSegmentIndex, presenter: self)
                if self.isPhotoMode {
                    self.studioConfiguration.configurePhotoInputOutput(presenter: self)
                } else {
                    self.studioConfiguration.configureMovieInputOutput(presenter: self)
                }
            }
        }
    }
    
}

// MARK: - OutputConverter

extension StudioViewController {
    
    private func addOutputConverterTarget() {
        self.outputConverter.addTarget(self, action: #selector(self.convertOutput), for: .valueChanged)
    }
    
    private func configureOutputConverter() {
        self.outputConverter.layer.borderWidth = 2
        self.outputConverter.layer.borderColor = UIColor.systemPink.cgColor
    }
    
    @objc func convertOutput(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            DispatchQueue.main.async {
                self.isPhotoMode = true
                if self.isPhotoMode {
                    self.recordTimerLabel.isHidden = true
                    self.convertStudioActionButtonText()
                    self.studioConfiguration.configurePhotoInputOutput(presenter: self)
                }
            }
        case 1:
            DispatchQueue.main.async {
                self.isPhotoMode = false
                if !self.isPhotoMode {
                    self.recordTimerLabel.isHidden = false
                    self.convertStudioActionButtonText()
                    self.studioConfiguration.configureMovieInputOutput(presenter: self)
                }
            }
        default:
            DispatchQueue.main.async {
                self.isPhotoMode = true
                if self.isPhotoMode {
                    self.recordTimerLabel.isHidden = true
                    self.convertStudioActionButtonText()
                    self.studioConfiguration.configurePhotoInputOutput(presenter: self)
                }
            }
        }
    }
    
}

// MARK: - Button

extension StudioViewController {
    
    private func configureStudioActionButton() {
        self.studioActionButton.setTitle("Take Photo", for: .normal)
        self.studioActionButton.addTarget(self, action: #selector(self.pressedStudioActionButton), for: .touchUpInside)
    }
    
    private func convertStudioActionButtonText() {
        if self.isPhotoMode {
            self.studioActionButton.setTitle("Take Photo", for: .normal)
        } else {
            self.studioActionButton.setTitle("Record Video", for: .normal)
        }
    }
    
    @objc func pressedStudioActionButton() {
        guard let photoOutput = self.studioConfiguration.photoOutput else { return }
        guard let photoSettings = self.studioConfiguration.photoSettings else { return }
        if self.isPhotoMode {
            self.viewModel.didPressTakePhotoButton(photoSettings: photoSettings, photoOutput: photoOutput)
        } else {
            if !self.isRecordOn {
                self.isRecordOn = true
                self.recordTimer.start()
                self.studioActionButton.setTitleColor(.red, for: .normal)
                guard let movieFileOutput = self.studioConfiguration.movieFileOutput else { return }
                self.viewModel.didPressRecordStartButton(movieFileOutput: movieFileOutput, recorder: self, deviceOrientation: self.studioConfiguration.deviceOrientaition)
            } else {
                self.isRecordOn = false
                self.recordTimer.stop()
                self.studioActionButton.setTitleColor(.white, for: .normal)
                guard let movieFileOutput = self.studioConfiguration.movieFileOutput else { return }
                self.viewModel.didPressRecordStopButton(movieFileOutput: movieFileOutput)
            }
        }
    }
    
}

// MARK: - Label

extension StudioViewController {
    
    private func configureRecordTimerLabel() {
        self.recordTimerLabel.textColor = .white
        self.recordTimerLabel.textAlignment = .center
        self.recordTimerLabel.isHidden = true
    }
    
}

// MARK: - Add subviews and layout

extension StudioViewController {
    
    private func addSubviews() {
        self.view.addSubview(self.captureOutputScreenView)
        self.view.addSubview(self.studioActionButton)
        self.view.addSubview(self.cameraConverter)
        self.view.addSubview(self.outputConverter)
        self.view.addSubview(self.recordTimerLabel)
    }
    
    private func configureLayout() {
        self.captureOutputScreenView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        self.studioActionButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(self.view.snp.bottom).offset(-60)
        }
        self.cameraConverter.snp.makeConstraints {
            $0.leading.equalTo(self.view.snp.leading).offset(100)
            $0.top.equalTo(self.view.snp.top).offset(80)
            $0.trailing.equalTo(self.view.snp.trailing).offset(-100)
            $0.height.equalTo(38)
        }
        self.outputConverter.snp.makeConstraints {
            $0.leading.equalTo(self.view.snp.leading).offset(100)
            $0.top.equalTo(self.cameraConverter.snp.bottom).offset(4)
            $0.trailing.equalTo(self.view.snp.trailing).offset(-100)
            $0.height.equalTo(38)
        }
        self.recordTimerLabel.snp.makeConstraints {
            $0.centerX.equalTo(self.view.snp.centerX)
            $0.bottom.equalTo(self.studioActionButton.snp.top).offset(-20)
        }
    }
    
}

// MARK: - ImageView

extension StudioViewController {
    
    private func configureCaptureOutputScreenView() {
        self.captureOutputScreenView.contentMode = .scaleAspectFit
    }
    
}
