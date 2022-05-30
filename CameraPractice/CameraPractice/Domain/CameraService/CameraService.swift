//
//  CameraService.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/29.
//

import AVFoundation

protocol CameraService {
    func configureSession()
    func startSession()
    func applyPreviewView(previewView: PreviewView)
}

final class DefaultCameraSerivce: CameraService {
    
    private let deviceConfiguration: CameraDeviceConfigurable & AudioDeviceConfigurable
    private var captureSession: AVCaptureSession = AVCaptureSession()
    private var photoOutput: CapturePhotoOutput?

    private let sessionQueue = DispatchQueue(label: "session queue")
    
    init(deviceConfiguration: CameraDeviceConfigurable & AudioDeviceConfigurable) {
        self.captureSession = AVCaptureSession()
        self.deviceConfiguration = deviceConfiguration
    }
    
    func configureSession() {
        DispatchQueue.main.async {
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .photo
            self.configureDevice()
            self.configureOutput()
        }
    }
    
    func startSession() {
        self.captureSession.startRunning()
    }
    
    func applyPreviewView(previewView: PreviewView) {
        previewView.session = self.captureSession
    }
    
}

extension DefaultCameraSerivce {
    
    private func configureDevice() {
        self.deviceConfiguration.configureCameraDevice(captureSession: self.captureSession)
        self.deviceConfiguration.configureAudioDevice(captureSession: self.captureSession)
    }
    
    private func configureOutput() {
        guard let photoOutput = photoOutput else { return }
        if self.captureSession.canAddOutput(photoOutput) {
            self.captureSession.addOutput(photoOutput)
        } else {
            self.captureSession.commitConfiguration()
        }
        self.captureSession.commitConfiguration()
    }
    
}
