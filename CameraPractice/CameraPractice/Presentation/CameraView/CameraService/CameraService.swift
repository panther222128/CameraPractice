//
//  CameraService.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/29.
//

import AVFoundation
import UIKit

protocol CameraService {
    func prepareToUseCamera<T>(at index: Int, presenter: T) where T: UIViewController & AVCaptureVideoDataOutputSampleBufferDelegate 
    func takePhoto()
}

final class DefaultCameraSerivce {
    
    private var captureSession: AVCaptureSession?
    private let deviceConfiguration: DeviceConfigurable
    private var photoSettings: AVCapturePhotoSettings
    private var captureInput: AVCaptureInput?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoOutput: AVCaptureVideoDataOutput?
    
    init(deviceConfiguration: DeviceConfigurable, photoSettings: AVCapturePhotoSettings) {
        self.captureSession = nil
        self.captureInput = nil
        self.deviceConfiguration = deviceConfiguration
        self.photoSettings = photoSettings
    }
    
}

extension DefaultCameraSerivce: CameraService {
    
    func prepareToUseCamera<T>(at index: Int, presenter: T) where T: UIViewController & AVCaptureVideoDataOutputSampleBufferDelegate {
        DispatchQueue.main.async {
            self.startSession()
            self.configureSession()
            switch index {
            case 0:
                self.configureDevice(cameraDevices: .builtInDualWideCamera)
            case 1:
                self.configureDevice(cameraDevices: .frontCamera)
            default:
                self.configureDevice(cameraDevices: .builtInDualWideCamera)
            }
            self.configureInput()
            self.configurePhotoOutput()
            self.configurePhotoSettings()
            self.configureVideoOutput(presenter: presenter)
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
        captureSession.commitConfiguration()
    }
    
    private func stopSession() {
        guard let captureSession = captureSession else { return }
        captureSession.stopRunning()
        self.captureSession = nil
    }
    
}

// MARK: - Device and input, output

extension DefaultCameraSerivce {
    
    private func configureDevice(cameraDevices: CameraDevices) {
        guard let captureSession = captureSession else { return }
        self.deviceConfiguration.configureCameraDevice(captureSession: captureSession, cameraDevices: cameraDevices)
        self.deviceConfiguration.configureAudioDevice(captureSession: captureSession)
        captureSession.commitConfiguration()
    }
    
    private func configureInput() {
        guard let captureDevice = self.deviceConfiguration.defaultVideoDevice else { return }
        guard let captureSession = captureSession else { return }
        do {
            self.captureInput = try AVCaptureDeviceInput(device: captureDevice)
            
            guard let photoInput = self.captureInput else { return }
            
            if captureSession.canAddInput(photoInput) {
                captureSession.addInput(photoInput)
            }
            captureSession.commitConfiguration()
        } catch {
            print(error.localizedDescription)
        }
        captureSession.commitConfiguration()
    }
    
    private func configurePhotoOutput() {
        guard let captureSession = captureSession else { return }
        guard let photoOutput = photoOutput else { return }
        
        photoOutput.isHighResolutionCaptureEnabled = true
        photoOutput.isLivePhotoCaptureEnabled = true
        photoOutput.isDepthDataDeliveryEnabled = true
        photoOutput.isPortraitEffectsMatteDeliveryEnabled = true
        
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        } else {
            captureSession.commitConfiguration()
        }
        
        captureSession.commitConfiguration()
    }
    
    private func configureVideoOutput<T>(presenter: T) where T: UIViewController & AVCaptureVideoDataOutputSampleBufferDelegate {
        guard let captureSession = captureSession else { return }
        
        self.videoOutput = AVCaptureVideoDataOutput()
        
        guard let videoOutput = self.videoOutput else { return }
        videoOutput.setSampleBufferDelegate(presenter, queue: DispatchQueue.main)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        captureSession.startRunning()
    }
    
}

// MARK: - PhotoSettings

extension DefaultCameraSerivce {
    
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
