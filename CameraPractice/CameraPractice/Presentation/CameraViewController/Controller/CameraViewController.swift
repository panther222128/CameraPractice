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
    
    // MARK: - Related with session
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    // MARK: - Photo input, output
    private let photoOutput = AVCapturePhotoOutput()
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    
    // MARK: - viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel.didCheckIsAuthorized()
        self.addSubviews()
        self.configureLayout()
        self.bind()
    }
    
    private func bind() {
        self.viewModel.isAuthorized.bind { [weak self] isAuthorized in
            guard let self = self else { return }
            if isAuthorized {
                DispatchQueue.main.async {
                    self.captureSession.startRunning()
                    self.configurePreviewSession()
                    self.configureSession()
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

// MARK: - Capture session

extension CameraViewController {
    
    private func configureSession() {
        // Session
        self.captureSession.beginConfiguration()
        self.captureSession.sessionPreset = .photo
        
        // Photo input
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let dualWideCameraDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                defaultVideoDevice = dualWideCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                defaultVideoDevice = frontCameraDevice
            }
            
            guard let videoDevice = defaultVideoDevice else {
                self.captureSession.commitConfiguration()
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if self.captureSession.canAddInput(videoDeviceInput) {
                self.captureSession.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async {
                    let initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                }
            } else {
                self.captureSession.commitConfiguration()
                return
            }
        } catch {
            self.captureSession.commitConfiguration()
            return
        }
        
        do {
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
            if self.captureSession.canAddInput(audioDeviceInput) {
                self.captureSession.addInput(audioDeviceInput)
            } else {
                print("Could not add audio device input to the session")
            }
        } catch {
            print("Could not create audio device input: \(error)")
        }
        
        // MARK: - Photo output
        if self.captureSession.canAddOutput(photoOutput) {
            self.captureSession.addOutput(photoOutput)
            
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
            photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
            photoOutput.isPortraitEffectsMatteDeliveryEnabled = photoOutput.isPortraitEffectsMatteDeliverySupported
            photoOutput.enabledSemanticSegmentationMatteTypes = photoOutput.availableSemanticSegmentationMatteTypes
        } else {
            self.captureSession.commitConfiguration()
            return
        }
        self.captureSession.commitConfiguration()
    }
    
}

// MARK: - Preview view

extension CameraViewController {
    
    private func configurePreviewSession() {
        self.previewView.session = captureSession
    }
    
}

// MARK: - Configure views

extension CameraViewController {
    
    private func addSubviews() {
        self.view.addSubview(self.previewView)
    }
    
    private func configureLayout() {
        self.previewView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
}
