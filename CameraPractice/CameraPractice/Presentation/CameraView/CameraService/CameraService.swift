//
//  CameraService.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/29.
//

import AVFoundation
import UIKit

protocol CameraService {
    func prepareToUseDevice<T>(at index: Int, presenter: T) where T: UIViewController & AVCaptureVideoDataOutputSampleBufferDelegate
    func capturePhoto()
}

final class DefaultCameraSerivce {
    
    private let deviceConfiguration: DeviceConfigurable
    private var captureSession: AVCaptureSession?
    private var photoSettings: AVCapturePhotoSettings
    private var captureInput: AVCaptureInput?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()
    
    init(deviceConfiguration: DeviceConfigurable, photoSettings: AVCapturePhotoSettings) {
        self.captureSession = nil
        self.captureInput = nil
        self.deviceConfiguration = deviceConfiguration
        self.photoSettings = photoSettings
    }
    
}

extension DefaultCameraSerivce: CameraService {
    
    func prepareToUseDevice<T>(at index: Int, presenter: T) where T: UIViewController & AVCaptureVideoDataOutputSampleBufferDelegate {
        DispatchQueue.main.async {
            self.startSession()
            self.configureSession()
            switch index {
            case 0:
                self.configureCameraDevice(cameraDevices: .builtInDualWideCamera)
            case 1:
                self.configureCameraDevice(cameraDevices: .frontCamera)
            default:
                self.configureCameraDevice(cameraDevices: .builtInDualWideCamera)
            }
            self.configureAudioDevice()
            self.configureInput()
            self.configurePhotoOutput()
            self.configurePhotoSettings()
            self.configureVideoOutput(presenter: presenter)
        }
    }
    
    func capturePhoto() {
        let photoCaptureProcessor = PhotoCaptureProcessor(with: self.photoSettings) { photoCaptureProcessor in
            DispatchQueue.main.async {
                self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
            }
        }

        self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor

        guard let photoOutput = self.photoOutput else { return }
        
        photoOutput.capturePhoto(with: self.photoSettings, delegate: photoCaptureProcessor)
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
    
    private func configureCameraDevice(cameraDevices: CameraDevices) {
        guard let captureSession = captureSession else { return }
        self.deviceConfiguration.configureCameraDevice(captureSession: captureSession, cameraDevices: cameraDevices)
        captureSession.commitConfiguration()
    }
    
    private func configureAudioDevice() {
        guard let captureSession = captureSession else { return }
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
        self.photoOutput = AVCapturePhotoOutput()
        guard let captureSession = captureSession else { return }
        guard let photoOutput = photoOutput else { return }
        
        photoOutput.isHighResolutionCaptureEnabled = true
        
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
        self.photoSettings.isHighResolutionPhotoEnabled = true
        if let previewPhotoPixelFormatType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            self.photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
        }

        self.photoSettings.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliveryEnabled
        self.photoSettings.isPortraitEffectsMatteDeliveryEnabled = photoOutput.isPortraitEffectsMatteDeliveryEnabled
        self.photoSettings.photoQualityPrioritization = .balanced
    }
    
}
