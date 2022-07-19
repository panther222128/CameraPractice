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
    private let outputConverterButton =  UIButton()
    private let cameraConverterButton = UIButton()
    private let recordTimerLabel = UILabel()
    private let sessionQueue = DispatchQueue(label: "session queue")
    private let dataInputOutputQueue = DispatchQueue(label: "datainputoutput queue")
    
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
        self.configureCameraConverterButton()
        self.configureOutputConverterButton()
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
                        self.studioConfiguration.configureDefaultMode(to: self, on: self.sessionQueue)
                        self.setOrientation()
                    }
                }
            } else {
                self.presentDeviceAccessAuthorizationStatusAlert()
            }
        }
        self.recordTimer.time.bind { [weak self] timeProgressStatus in
            guard let self = self else { return }
            self.recordTimerLabel.text = timeProgressStatus
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
        if output == self.studioConfiguration.videoDataOutput {
            self.processFullScreenSampleBuffer(fullScreenSampleBuffer: sampleBuffer)
        } else if output == self.studioConfiguration.backAudioDataOutput {
            self.processAudioSampleBuffer(sampleBuffer: sampleBuffer)
        }
    }
    
    private func processFullScreenSampleBuffer(fullScreenSampleBuffer: CMSampleBuffer) {
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

    private func processAudioSampleBuffer(sampleBuffer: CMSampleBuffer) {
        self.viewModel.recordAudio(sampleBuffer: sampleBuffer)
    }
    
}

// MARK: - CameraConverter

extension StudioViewController {
    
    private func configureCameraConverterButton() {
        self.cameraConverterButton.setTitle("Change Camera", for: .normal)
        self.cameraConverterButton.addTarget(self, action: #selector(self.convertCamera), for: .touchUpInside)
    }
    
    @objc func convertCamera() {
        self.studioConfiguration.convertCamera(at: self, on: self.sessionQueue)
    }
    
}

// MARK: - OutputConverter

extension StudioViewController {
    
    private func configureOutputConverterButton() {
        self.outputConverterButton.setTitle("Photo", for: .normal)
        self.outputConverterButton.addTarget(self, action: #selector(self.convertOutput), for: .touchUpInside)
    }
    
    @objc func convertOutput() {
        if self.isPhotoMode {
            self.isPhotoMode = false
            self.studioConfiguration.configureMovieMode(to: self, on: self.sessionQueue)
            self.outputConverterButton.setTitle("Movie", for: .normal)
            self.studioActionButton.setTitle("Record Movie", for: .normal)
            self.recordTimerLabel.isHidden = false
        } else {
            self.isPhotoMode = true
            self.studioConfiguration.configurePhotoMode()
            self.outputConverterButton.setTitle("Photo", for: .normal)
            self.studioActionButton.setTitle("Take Photo", for: .normal)
            self.recordTimerLabel.isHidden = true
        }
    }
    
}

// MARK: - Button

extension StudioViewController {
    
    private func configureStudioActionButton() {
        self.studioActionButton.setTitle("Take Photo", for: .normal)
        self.studioActionButton.addTarget(self, action: #selector(self.pressedStudioActionButtonAction), for: .touchUpInside)
    }
    
    @objc func pressedStudioActionButtonAction() {
        guard let photoOutput = self.studioConfiguration.photoOutput else { return }
        guard let photoSettings = self.studioConfiguration.photoSettings else { return }
        if self.isPhotoMode {
            self.viewModel.didPressTakePhotoButton(photoSettings: photoSettings, photoOutput: photoOutput)
            self.studioConfiguration.setPhotoOption()
        } else {
            if !self.isRecordOn {
                self.isRecordOn = true
                self.recordTimer.start()
                self.studioActionButton.setTitleColor(.red, for: .normal)
                self.dataInputOutputQueue.async {
                    self.studioConfiguration.createVideoTransform(videoDataOutput: self.studioConfiguration.videoDataOutput)
                    guard let videoTransform = self.studioConfiguration.videoTransform else { return }
                    self.viewModel.didPressRecordStartButton(videoTransform: videoTransform, videoDataOutput: self.studioConfiguration.videoDataOutput, audioDataOutput: self.studioConfiguration.backAudioDataOutput)
                }
            } else {
                self.isRecordOn = false
                self.recordTimer.stop()
                self.studioActionButton.setTitleColor(.white, for: .normal)
                self.dataInputOutputQueue.async {
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
        self.view.addSubview(self.cameraConverterButton)
        self.view.addSubview(self.outputConverterButton)
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
        self.cameraConverterButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(self.outputConverterButton.snp.top).offset(40)
        }
        self.outputConverterButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalTo(self.view.snp.top).offset(80)
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
