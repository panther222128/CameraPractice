//
//  CameraService.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/29.
//

import AVFoundation

protocol CameraService {
    func takePhoto(previewView: PreviewView)
    func prepareToTakePhoto(previewView: PreviewView)
}

final class DefaultCameraSerivce {
    
    private var captureSession: AVCaptureSession?
    private let deviceConfiguration: CameraDeviceConfigurable & AudioDeviceConfigurable
    private var photoSettings: AVCapturePhotoSettings
    private var photoOutput: CapturePhotoOutput?
    
    init(deviceConfiguration: CameraDeviceConfigurable & AudioDeviceConfigurable, photoSettings: AVCapturePhotoSettings) {
        self.captureSession = nil
        self.deviceConfiguration = deviceConfiguration
        self.photoSettings = photoSettings
    }
    
}

extension DefaultCameraSerivce: CameraService {
    
    func takePhoto(previewView: PreviewView) {
        self.prepareToTakePhoto(previewView: previewView)
    }
    
}

extension DefaultCameraSerivce {
    
    func prepareToTakePhoto(previewView: PreviewView) {
        DispatchQueue.main.async {
            self.startSession()
            self.configureSession()
            self.configureDevice()
            self.configureOutput()
            self.applyPreviewView(previewView: previewView)
        }
    }
    
}

// MARK: - Session and previewview

extension DefaultCameraSerivce {
    
    private func startSession() {
        self.captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        captureSession.startRunning()
    }

    private func configureSession() {
        guard let captureSession = self.captureSession else { return }
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
    }

    private func applyPreviewView(previewView: PreviewView) {
        previewView.session = self.captureSession
    }

    private func stopSession() {
        guard let captureSession = captureSession else { return }
        captureSession.stopRunning()
        self.captureSession = nil
    }
    
}

// MARK: - Device

extension DefaultCameraSerivce {
    
    private func configureDevice() {
        guard let captureSession = captureSession else { return }
        self.deviceConfiguration.configureCameraDevice(captureSession: captureSession)
        self.deviceConfiguration.configureAudioDevice(captureSession: captureSession)
    }
    
    private func configureOutput() {
        guard let captureSession = captureSession else { return }
        guard let photoOutput = photoOutput else { return }
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        } else {
            captureSession.commitConfiguration()
        }
        captureSession.commitConfiguration()
    }
    
}

// MARK: - PhotoOutput and PhotoSettings

extension DefaultCameraSerivce {
    
    private func configurePhotoOutput(previewView: PreviewView) {
        guard let photoOutput = photoOutput else { return }
        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
        
        if let photoOutputConnection = photoOutput.connection(with: .video) {
            photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
        }
    }
    
    private func configurePhotoSettings() {
        guard let photoOutput = photoOutput else { return }
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        }
        if self.deviceConfiguration.isDeviceFlashAvailable() {
            photoSettings.flashMode = .auto
        }
    }
    
}
