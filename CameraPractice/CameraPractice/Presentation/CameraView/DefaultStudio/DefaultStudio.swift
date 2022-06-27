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
    var videoDataOutput: AVCaptureVideoDataOutput? { get }
    var audioDataOutput: AVCaptureAudioDataOutput? { get }
    var movieFileOutput: AVCaptureMovieFileOutput? { get }
    var deviceOrientaition: AVCaptureVideoOrientation { get }
    
    func configureEnvironment(at index: Int, presenter: some UIViewController & DataOutputSampleBufferDelegate)
    func configurePhotoInputOutput(presenter: some UIViewController & DataOutputSampleBufferDelegate)
    func configureMovieInputOutput(presenter: some UIViewController & DataOutputSampleBufferDelegate)
    
    func invalidateStudio()
}

final class DefaultStudio: StudioConfigurable {
    
    private let deviceConfiguration: DeviceConfigurable
    
    var photoSettings: AVCapturePhotoSettings?
    var photoOutput: AVCapturePhotoOutput?
    var videoDataOutput: AVCaptureVideoDataOutput?
    var audioDataOutput: AVCaptureAudioDataOutput?
    var movieFileOutput: AVCaptureMovieFileOutput?
    var deviceOrientaition: AVCaptureVideoOrientation = .portrait
    
    private var captureSession: AVCaptureSession?
    private var captureInput: AVCaptureInput?
    
    init(deviceConfiguration: DeviceConfigurable, photoSettings: AVCapturePhotoSettings) {
        self.captureSession = nil
        self.captureInput = nil
        self.deviceConfiguration = deviceConfiguration
        self.photoSettings = photoSettings
    }
    
    func configureEnvironment(at index: Int, presenter: some UIViewController & DataOutputSampleBufferDelegate) {
        switch index {
        case 0:
            self.captureSessionBeginConfiguration()
            self.configureSession()
            self.startSession()
            
            self.configureCameraDevice(cameraDevices: .builtInDualWideCamera)
            self.configureAudioDevice()
            
            self.configureAudioDataOutput(presenter: presenter)
            self.configureVideoDataOutput(presenter: presenter)
        case 1:
            self.captureSessionBeginConfiguration()
            self.configureSession()
            self.startSession()
            
            self.configureCameraDevice(cameraDevices: .frontCamera)
            self.configureAudioDevice()
            
            self.configureAudioDataOutput(presenter: presenter)
            self.configureVideoDataOutput(presenter: presenter)
        default:
            self.captureSessionBeginConfiguration()
            self.configureSession()
            self.startSession()
            
            self.configureCameraDevice(cameraDevices: .builtInDualWideCamera)
            self.configureAudioDevice()
            
            self.configureAudioDataOutput(presenter: presenter)
            self.configureVideoDataOutput(presenter: presenter)
        }
    }
    
    /* MARK: - Available from Swift 5.7
     same
     func configurePhotoInputOutput<T>(presenter: T) where T: UIViewController & DataOutputSampleBufferDelegate { ... }
     func configurePhotoInputOutput(presenter: some UIViewController & DataOutputSampleBufferDelegate) { ... }
     */
    
    func configurePhotoInputOutput(presenter: some UIViewController & DataOutputSampleBufferDelegate) {
        self.configureInput()
        self.configurePhotoOutput()
        self.configurePhotoSettings()
        self.configureAudioDataOutput(presenter: presenter)
        self.configureVideoDataOutput(presenter: presenter)
    }
    
    func configureMovieInputOutput(presenter: some UIViewController & DataOutputSampleBufferDelegate) {
        self.configureInput()
        self.configureMovieFileOutput()
        self.configureAudioDataOutput(presenter: presenter)
        self.configureVideoDataOutput(presenter: presenter)
    }
    
    func invalidateStudio() {
        self.stopSession()
        self.photoSettings = nil
        self.photoOutput = nil
        self.videoDataOutput = nil
        self.audioDataOutput = nil
        self.movieFileOutput = nil
    }
    
}

// MARK: - Session

extension DefaultStudio {
    
    private func startSession() {
        self.captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        DispatchQueue.global(qos: .userInteractive).async {
            captureSession.startRunning()
        }
    }
    
    private func captureSessionBeginConfiguration() {
        guard let captureSession = self.captureSession else { return }
        captureSession.beginConfiguration()
    }
    
    private func configureSession() {
        guard let captureSession = self.captureSession else { return }
        captureSession.sessionPreset = .high
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
    }
    
}

// MARK: - MovieFileOutput

extension DefaultStudio {
    
    private func configureMovieFileOutput() {
        guard let captureSession = self.captureSession else { return }
        
        self.movieFileOutput = AVCaptureMovieFileOutput()
        
        guard let movieFileOutput = self.movieFileOutput else { return }
        
        if captureSession.canAddOutput(movieFileOutput) {
            captureSession.addOutput(movieFileOutput)
        }
        
        captureSession.commitConfiguration()
    }
    
}
