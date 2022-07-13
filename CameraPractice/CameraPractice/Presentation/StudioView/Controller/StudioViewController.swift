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
    private let presentMediaPickerViewButton = UIButton()
    private let screenMetalView = ScreenMetalView(frame: CGRect(origin: .zero, size: CGSize(width: 0, height: 0)), device: MTLCreateSystemDefaultDevice())
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
    private let sessionQueue = DispatchQueue(label: "session queue")
    private let dataInputOutpitQueue = DispatchQueue(label: "datainputoutput queue")
    
    private var isPhotoMode = true
    private var isRecordOn = false
    
    private var currentDepthPixelBuffer: CVPixelBuffer?
    private var depthVisualizationEnabled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bind()
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
        self.configureGoToMediaPickerButton()
    }
    
    private func bind() {
        self.viewModel.isDeviceAccessAuthorized.bind { [weak self] isAuthorized in
            guard let self = self else { return }
            guard let isAuthorized = isAuthorized else { return }
            if isAuthorized {
                DispatchQueue.main.async {
                    self.sessionQueue.async {
                        self.studioConfiguration.configureEnvironment(at: 0, presenter: self, with: .builtInDualWideCamera, sessionQueue: self.sessionQueue)
                        self.setOrientation()
                    }
                }
            } else {
                self.presentDeviceAccessAuthorizationStatusAlert()
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

extension StudioViewController {
    
    private func setOrientation() {
        DispatchQueue.main.async {
            guard let connection = self.studioConfiguration.videoDataOutput.connection(with: .video) else { return }
            guard let firstWindow = UIApplication.shared.windows.first else { return }
            guard let windowScene = firstWindow.windowScene else { return }
            let orientation = windowScene.interfaceOrientation
            guard let rotation = ScreenMetalView.Rotation(with: orientation, videoOrientation: connection.videoOrientation, cameraPosition: .back) else { return }
            self.screenMetalView.rotation = rotation
        }
    }
    
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension StudioViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        self.screenMetalView.pixelBuffer = videoPixelBuffer
        if let videoDataOutput = output as? AVCaptureVideoDataOutput {
            self.processFullScreenSampleBuffer(fullScreenSampleBuffer: sampleBuffer, from: videoDataOutput)
        }
        if let audioDataOutput = output as? AVCaptureAudioDataOutput {
            self.processAudioSampleBuffer(sampleBuffer: sampleBuffer, from: audioDataOutput)
        }
    }
    
    private func processFullScreenSampleBuffer(fullScreenSampleBuffer: CMSampleBuffer, from videoDataOutput: AVCaptureVideoDataOutput) {
        guard let fullScreenPixelBuffer = CMSampleBufferGetImageBuffer(fullScreenSampleBuffer) else { return }
        guard let formatDescription = CMSampleBufferGetFormatDescription(fullScreenSampleBuffer) else { return }
        guard let sampleBuffer = self.createVideoSampleBufferWithPixelBuffer(fullScreenPixelBuffer, formatDescription: formatDescription, presentationTime: CMSampleBufferGetPresentationTimeStamp(fullScreenSampleBuffer)) else { return }
        self.viewModel.recordVideo(sampleBuffer: sampleBuffer)
    }
    
    private func createVideoSampleBufferWithPixelBuffer(_ pixelBuffer: CVPixelBuffer, formatDescription: CMFormatDescription, presentationTime: CMTime) -> CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer?
        var timingInfo = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: presentationTime, decodeTimeStamp: .invalid)
        
        let err = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                     imageBuffer: pixelBuffer,
                                                     dataReady: true,
                                                     makeDataReadyCallback: nil,
                                                     refcon: nil,
                                                     formatDescription: formatDescription,
                                                     sampleTiming: &timingInfo,
                                                     sampleBufferOut: &sampleBuffer)
        if sampleBuffer == nil {
            print("Error: Sample buffer creation failed (error code: \(err))")
        }
        
        return sampleBuffer
    }

    private func processAudioSampleBuffer(sampleBuffer: CMSampleBuffer, from audioDataOutput: AVCaptureAudioDataOutput) {
        self.viewModel.recordAudio(sampleBuffer: sampleBuffer)
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
                self.sessionQueue.async {
                    self.studioConfiguration.convertCamera(to: .builtInDualWideCamera, presenter: self, sessionQueue: self.sessionQueue)
                }
            }
        case 1:
            DispatchQueue.main.async {
                self.sessionQueue.async {
                    self.studioConfiguration.convertCamera(to: .frontCamera, presenter: self, sessionQueue: self.sessionQueue)
                }
            }
        default:
            DispatchQueue.main.async {
                self.sessionQueue.async {
                    self.studioConfiguration.convertCamera(to: .builtInDualWideCamera, presenter: self, sessionQueue: self.sessionQueue)
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
                }
            }
        case 1:
            DispatchQueue.main.async {
                self.isPhotoMode = false
                if !self.isPhotoMode {
                    self.recordTimerLabel.isHidden = false
                    self.convertStudioActionButtonText()
                }
            }
        default:
            DispatchQueue.main.async {
                self.isPhotoMode = true
                if self.isPhotoMode {
                    self.recordTimerLabel.isHidden = true
                    self.convertStudioActionButtonText()
                }
            }
        }
    }
    
}

// MARK: - Button

extension StudioViewController {
    
    private func configureStudioActionButton() {
        self.studioActionButton.setTitle("Take Photo", for: .normal)
        self.studioActionButton.addTarget(self, action: #selector(self.pressedStudioActionButtonAction), for: .touchUpInside)
    }
    
    private func convertStudioActionButtonText() {
        if self.isPhotoMode {
            self.studioActionButton.setTitle("Take Photo", for: .normal)
        } else {
            self.studioActionButton.setTitle("Record Video", for: .normal)
        }
    }
    
    @objc func pressedStudioActionButtonAction() {
        guard let photoOutput = self.studioConfiguration.photoOutput else { return }
        guard let photoSettings = self.studioConfiguration.photoSettings else { return }
        if self.isPhotoMode {
            self.viewModel.didPressTakePhotoButton(photoSettings: photoSettings, photoOutput: photoOutput)
        } else {
            if !self.isRecordOn {
                self.isRecordOn = true
                self.recordTimer.start()
                self.studioActionButton.setTitleColor(.red, for: .normal)
                self.dataInputOutpitQueue.async {
                    self.studioConfiguration.createVideoTransform(videoDataOutput: self.studioConfiguration.videoDataOutput)
                    guard let videoTransform = self.studioConfiguration.videoTransform else { return }
                    self.viewModel.didPressRecordStartButton(videoTransform: videoTransform, videoDataOutput: self.studioConfiguration.videoDataOutput, audioDataOutput: self.studioConfiguration.audioDataOutput)
                }
            } else {
                self.isRecordOn = false
                self.recordTimer.stop()
                self.studioActionButton.setTitleColor(.white, for: .normal)
                self.dataInputOutpitQueue.async {
                    self.viewModel.didPressRecordStopButton { url in
                        self.viewModel.saveMovie(outputUrl: url)
                    }
                }
            }
        }
    }
    
    private func configureGoToMediaPickerButton() {
        self.presentMediaPickerViewButton.setTitle("Image", for: .normal)
        self.presentMediaPickerViewButton.addTarget(self, action: #selector(self.presentMediaPickverViewButtonAction), for: .touchUpInside)
    }
    
    @objc func presentMediaPickverViewButtonAction() {
        self.viewModel.didPressPresentMediaPickerViewButton()
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
        self.view.addSubview(self.screenMetalView)
        self.view.addSubview(self.studioActionButton)
        self.view.addSubview(self.cameraConverter)
        self.view.addSubview(self.outputConverter)
        self.view.addSubview(self.recordTimerLabel)
        self.view.addSubview(self.presentMediaPickerViewButton)
    }
    
    private func configureLayout() {
        self.screenMetalView.snp.makeConstraints {
            $0.leading.equalTo(self.view.safeAreaLayoutGuide)
            $0.top.equalTo(self.view.safeAreaLayoutGuide)
            $0.trailing.equalTo(self.view.safeAreaLayoutGuide)
            $0.bottom.equalTo(self.view.safeAreaLayoutGuide)
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
        self.presentMediaPickerViewButton.snp.makeConstraints {
            $0.top.trailing.equalTo(self.view.safeAreaLayoutGuide)
            $0.height.equalTo(24)
        }
    }
    
}
