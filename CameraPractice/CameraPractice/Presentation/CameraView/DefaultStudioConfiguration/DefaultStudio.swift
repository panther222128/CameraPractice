//
//  CameraService.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/29.
//

import AVFoundation
import UIKit

protocol StudioConfigurable {
    var photoSettings: AVCapturePhotoSettings? { get }
    var photoOutput: AVCapturePhotoOutput? { get }
    var deviceOrientaition: AVCaptureVideoOrientation { get }
    var videoDataOutput: AVCaptureVideoDataOutput? { get }
    var audioDataOutput: AVCaptureAudioDataOutput? { get }
    var movieFileOutput: AVCaptureMovieFileOutput? { get }

    func prepareToTakeAction(at index: Int, presenter: some UIViewController & DataOutputSampleBufferDelegate)
}

final class DefaultStudio: StudioConfigurable {
    
    private let deviceConfiguration: DeviceConfigurable
    
    var photoSettings: AVCapturePhotoSettings?
    var photoOutput: AVCapturePhotoOutput?
    var deviceOrientaition: AVCaptureVideoOrientation = .portrait
    var videoDataOutput: AVCaptureVideoDataOutput?
    var audioDataOutput: AVCaptureAudioDataOutput?
    var movieFileOutput: AVCaptureMovieFileOutput?
    
    private var captureSession: AVCaptureSession?
    private var captureInput: AVCaptureInput?

    init(deviceConfiguration: DeviceConfigurable, photoSettings: AVCapturePhotoSettings) {
        self.captureSession = nil
        self.captureInput = nil
        self.deviceConfiguration = deviceConfiguration
        self.photoSettings = photoSettings
    }
    
    /* MARK: - Available from Swift 5.7
     same
     func prepareToUseDevice<T>(at index: Int, presenter: T) where T: UIViewController & AVCaptureVideoDataOutputSampleBufferDelegate { ... }
     func prepareToUseDevice(at index: Int, presenter: some UIViewController & AVCaptureVideoDataOutputSampleBufferDelegate) { ... }
     */
    
    func prepareToTakeAction(at index: Int, presenter: some UIViewController & DataOutputSampleBufferDelegate) {
        DispatchQueue.main.async {
            self.configureSession()
            self.startSession()
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
            self.configureMovieFileOutput(presenter: presenter)
            self.configureAudioDataOutput(presenter: presenter)
            self.configureVideoDataOutput(presenter: presenter)
        }
    }

}

// MARK: - Session

extension DefaultStudio {
    
    private func startSession() {
        self.captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        captureSession.startRunning()
    }
    
    private func configureSession() {
        guard let captureSession = self.captureSession else { return }
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .inputPriority
        captureSession.commitConfiguration()
    }
    
    private func stopSession() {
        guard let captureSession = captureSession else { return }
        captureSession.stopRunning()
        self.captureSession = nil
    }
    
}

// MARK: - Device and input, output

extension DefaultStudio {
    
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
        guard let captureDevice = self.deviceConfiguration.defaultDevice else { return }
        guard let captureSession = captureSession else { return }
        do {
            self.captureInput = try AVCaptureDeviceInput(device: captureDevice)
            
            guard let captureInput = self.captureInput else { return }
            
            if captureSession.canAddInput(captureInput) {
                captureSession.addInput(captureInput)
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
    
    /* MARK: - Available from Swift 5.7
     same
     private func configureVideoDataOutput<T>(presenter: T) where T: UIViewController & AVCaptureVideoDataOutputSampleBufferDelegate
     private func configureVideoDataOutput(presenter: some UIViewController & AVCaptureVideoDataOutputSampleBufferDelegate)
     */
    
    private func configureVideoDataOutput(presenter: some UIViewController & AVCaptureVideoDataOutputSampleBufferDelegate) {
        guard let captureSession = captureSession else { return }
        
        self.videoDataOutput = AVCaptureVideoDataOutput()
        
        guard let videoOutput = self.videoDataOutput else { return }
        videoOutput.setSampleBufferDelegate(presenter, queue: DispatchQueue.main)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.commitConfiguration()
    }
    
    /* MARK: - Available from Swift 5.7
     same
     private func configureAudioDataOutput<T>(presenter: T) where T: UIViewController & AVCaptureVideoDataOutputSampleBufferDelegate
     private func configureAudioDataOutput(presenter: some UIViewController & AVCaptureAudioDataOutputSampleBufferDelegate)
     */
    
    private func configureAudioDataOutput(presenter: some UIViewController & AVCaptureAudioDataOutputSampleBufferDelegate) {
        guard let captureSession = captureSession else { return }
        
        self.audioDataOutput = AVCaptureAudioDataOutput()
        
        guard let audioOutput = self.audioDataOutput else { return }
        audioOutput.setSampleBufferDelegate(presenter, queue: DispatchQueue.main)
        if captureSession.canAddOutput(audioOutput) {
            captureSession.addOutput(audioOutput)
        }
        
        captureSession.commitConfiguration()
    }
    
}

// MARK: - PhotoSettings

extension DefaultStudio {
    
    private func configurePhotoSettings() {
        guard let photoOutput = photoOutput else { return }
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        }
        guard let photoSettings = self.photoSettings else { return }

        photoSettings.isHighResolutionPhotoEnabled = true
        if let previewPhotoPixelFormatType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
        }

        photoSettings.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliveryEnabled
        photoSettings.isPortraitEffectsMatteDeliveryEnabled = photoOutput.isPortraitEffectsMatteDeliveryEnabled
        photoSettings.photoQualityPrioritization = .balanced
    }
    
}

// MARK: - MovieFileOutput

extension DefaultStudio {
    
    private func configureMovieFileOutput(presenter: some UIViewController & DataOutputSampleBufferDelegate) {
        self.movieFileOutput = AVCaptureMovieFileOutput()
        
        guard let captureSession = self.captureSession else { return }
        guard let movieFileOutput = self.movieFileOutput else { return }

        if captureSession.canAddOutput(movieFileOutput) {
            captureSession.addOutput(movieFileOutput)
        }

        captureSession.commitConfiguration()
    }
    
}
