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
    var videoDataOutput: AVCaptureVideoDataOutput { get }
    var backAudioDataOutput: AVCaptureAudioDataOutput { get }
    var videoTransform: CGAffineTransform? { get }
    
    func configureDefaultMode<T>(to presenter: T, on sessionQueue: DispatchQueue) where T: AVCaptureVideoDataOutputSampleBufferDelegate & UIViewController
    func configureMovieMode<T>(to presenter: T, on sessionQueue: DispatchQueue) where T: AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate & UIViewController
    func configurePhotoMode()
    func convertCamera<T>(at presenter: T, on sessionQueue: DispatchQueue) where T: AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate & UIViewController
    func setPhotoOption()
    
    func createVideoTransform(videoDataOutput: AVCaptureVideoDataOutput)
    
    func invalidateStudio()
}

final class DefaultStudio: StudioConfigurable {
    
    private let deviceConfiguration: DeviceConfigurable
    
    var photoSettings: AVCapturePhotoSettings?
    var photoOutput: AVCapturePhotoOutput?
    var videoDataOutput: AVCaptureVideoDataOutput
    var backAudioDataOutput: AVCaptureAudioDataOutput
    var frontAudioDataOutput: AVCaptureAudioDataOutput
    var videoTransform: CGAffineTransform?
    
    private let captureSession: AVCaptureSession
    
    private var isPhotoMode: Bool
    private var isBackCamera: Bool

    init(deviceConfiguration: DeviceConfigurable, photoSettings: AVCapturePhotoSettings) {
        self.captureSession = AVCaptureSession()
        self.deviceConfiguration = deviceConfiguration
        self.photoSettings = photoSettings
        self.videoTransform = nil
        self.videoDataOutput = AVCaptureVideoDataOutput()
        self.backAudioDataOutput = AVCaptureAudioDataOutput()
        self.frontAudioDataOutput = AVCaptureAudioDataOutput()
        self.isPhotoMode = true
        self.isBackCamera = true
    }
    
    func configureDefaultMode<T>(to presenter: T, on sessionQueue: DispatchQueue) where T: AVCaptureVideoDataOutputSampleBufferDelegate & UIViewController {
        self.captureSession.startRunning()
        self.captureSession.beginConfiguration()
        defer {
            self.captureSession.commitConfiguration()
        }
        
        self.captureSession.sessionPreset = .high
        
        self.configureVideoDevice(devicePosition: .back)
        self.setPhotoOption()
        self.setVideoOption(to: presenter, on: sessionQueue)
    }
    
    func configureMovieMode<T>(to presenter: T, on sessionQueue: DispatchQueue) where T: AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate & UIViewController {
        self.isPhotoMode = false
        self.captureSession.beginConfiguration()
        defer {
            self.captureSession.commitConfiguration()
        }
        
        guard let photoOutput = self.photoOutput else { return }
        self.captureSession.removeOutput(photoOutput)

        self.deviceConfiguration.configureAudioDevice(audioDataOutput: self.backAudioDataOutput)
        
        guard let audioDeviceInput = self.deviceConfiguration.audioDeviceInput else { return }
        
        if self.captureSession.canAddInput(audioDeviceInput) {
            self.captureSession.addInput(audioDeviceInput)
        }
        
        self.setVideoOption(to: presenter, on: sessionQueue)
        self.setAudioOption(to: presenter, on: sessionQueue)
    }
    
    func configurePhotoMode() {
        self.isPhotoMode = true
        self.captureSession.beginConfiguration()
        defer {
            self.captureSession.commitConfiguration()
        }
        
        self.captureSession.removeOutput(self.backAudioDataOutput)
        self.setPhotoOption()
    }
    
    func convertCamera<T>(at presenter: T, on sessionQueue: DispatchQueue) where T: AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate & UIViewController {
        self.captureSession.beginConfiguration()
        defer {
            self.captureSession.commitConfiguration()
        }
        guard let videoDeviceInput = self.deviceConfiguration.videoDeviceInput else { return }
        let devicePosition = videoDeviceInput.device.position
        self.captureSession.removeInput(videoDeviceInput)
        
        if devicePosition == .back {
            self.isBackCamera = false
            self.configureVideoDevice(devicePosition: .front)
            self.setVideoOption(to: presenter, on: sessionQueue)
            if self.isPhotoMode  {
                self.setPhotoOption()
            } else {
                self.deviceConfiguration.configureAudioDevice(audioDataOutput: self.backAudioDataOutput)
                self.setAudioOption(to: presenter, on: sessionQueue)
            }
        } else if devicePosition == .front {
            self.isBackCamera = true
            self.configureVideoDevice(devicePosition: .back)
            self.setVideoOption(to: presenter, on: sessionQueue)
            if self.isPhotoMode {
                self.setPhotoOption()
            } else {
                self.deviceConfiguration.configureAudioDevice(audioDataOutput: self.frontAudioDataOutput)
                self.setAudioOption(to: presenter, on: sessionQueue)
            }
        }
    }
    
    private func configureVideoDevice(devicePosition: AVCaptureDevice.Position) {
        switch devicePosition {
        case .back:
            self.deviceConfiguration.configureCameraDevice(cameraDevices: .builtInDualWideCamera, videoDataOutput: self.videoDataOutput)
        case .front:
            self.deviceConfiguration.configureCameraDevice(cameraDevices: .frontCamera, videoDataOutput: self.videoDataOutput)
        case .unspecified:
            self.deviceConfiguration.configureCameraDevice(cameraDevices: .builtInDualWideCamera, videoDataOutput: self.videoDataOutput)
        @unknown default:
            fatalError()
        }
        
        guard let videoDeviceInput = self.deviceConfiguration.videoDeviceInput else { return }
        
        if self.captureSession.canAddInput(videoDeviceInput) {
            self.captureSession.addInputWithNoConnections(videoDeviceInput)
        }
    }
    
    private func configureAudioDevice() {
        guard let audioDeviceInput = self.deviceConfiguration.audioDeviceInput else { return }
        
        if self.captureSession.canAddInput(audioDeviceInput) {
            self.captureSession.addInputWithNoConnections(audioDeviceInput)
        }
    }
    
    func setPhotoOption() {
        if let photoOutput = self.photoOutput {
            self.captureSession.removeOutput(photoOutput)
        }
        
        self.photoOutput = AVCapturePhotoOutput()
        guard let photoOutput = self.photoOutput else { return }
        photoOutput.isHighResolutionCaptureEnabled = true
        if self.captureSession.canAddOutput(photoOutput) {
            self.captureSession.addOutputWithNoConnections(photoOutput)
        }
        if photoOutput.availablePhotoCodecTypes.contains(.h264) {
            self.photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.h264])
        }
        
        guard let photoSettings = self.photoSettings else { return }
        photoSettings.isHighResolutionPhotoEnabled = true
        if let previewPhotoPixelFormatType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
        }
        photoSettings.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliveryEnabled
        photoSettings.isPortraitEffectsMatteDeliveryEnabled = photoOutput.isPortraitEffectsMatteDeliveryEnabled
        
        guard let videoDeviceInput = self.deviceConfiguration.videoDeviceInput else { return }
        guard let videoInputPort = videoDeviceInput.ports(for: .video, sourceDeviceType: videoDeviceInput.device.deviceType, sourceDevicePosition: videoDeviceInput.device.position).first else { return }
        let videoPhotoDataOutputConnection = AVCaptureConnection(inputPorts: [videoInputPort], output: photoOutput)
        
        if self.captureSession.canAddConnection(videoPhotoDataOutputConnection) {
            self.captureSession.addConnection(videoPhotoDataOutputConnection)
        }
    }
    
    private func setVideoOption<T>(to presenter: T, on sessionQueue: DispatchQueue) where T: AVCaptureVideoDataOutputSampleBufferDelegate & UIViewController {
        self.videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        
        if self.captureSession.canAddOutput(self.videoDataOutput) {
            self.captureSession.addOutputWithNoConnections(self.videoDataOutput)
        }
        
        self.videoDataOutput.setSampleBufferDelegate(presenter, queue: sessionQueue)
        
        guard let videoDeviceInput = self.deviceConfiguration.videoDeviceInput else { return }
        
        if isBackCamera {
            guard let videoInputPort = videoDeviceInput.ports(for: .video, sourceDeviceType: videoDeviceInput.device.deviceType, sourceDevicePosition: .back).first else { return }
            let videoDataOutputConnection = AVCaptureConnection(inputPorts: [videoInputPort], output: self.videoDataOutput)
            if self.captureSession.canAddConnection(videoDataOutputConnection) {
                self.captureSession.addConnection(videoDataOutputConnection)
            }
        } else {
            guard let videoInputPort = videoDeviceInput.ports(for: .video, sourceDeviceType: videoDeviceInput.device.deviceType, sourceDevicePosition: .front).first else { return }
            let videoDataOutputConnection = AVCaptureConnection(inputPorts: [videoInputPort], output: self.videoDataOutput)
            if self.captureSession.canAddConnection(videoDataOutputConnection) {
                self.captureSession.addConnection(videoDataOutputConnection)
            }
        }
    }
    
    private func setAudioOption<T>(to presenter: T, on sessionQueue: DispatchQueue) where T: AVCaptureAudioDataOutputSampleBufferDelegate & UIViewController {
        if self.captureSession.canAddOutput(self.backAudioDataOutput) {
            self.captureSession.addOutput(self.backAudioDataOutput)
        }
        self.backAudioDataOutput.setSampleBufferDelegate(presenter, queue: sessionQueue)
    }
    
    func invalidateStudio() {
        self.stopSession()
        self.photoSettings = nil
        self.photoOutput = nil
    }
    
}

// MARK: - Session

extension DefaultStudio {

    private func stopSession() {
        self.captureSession.stopRunning()
    }
    
}

extension DefaultStudio {
    
    func createVideoTransform(videoDataOutput: AVCaptureVideoDataOutput) {
        guard let videoConnection = videoDataOutput.connection(with: .video) else {
            print("Could not find the back and front camera video connections")
            return
        }
        
        let deviceOrientation = UIDevice.current.orientation
        let videoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation) ?? .portrait
        
        let cameraTransform = videoConnection.videoOrientationTransform(relativeTo: videoOrientation)
        
        self.videoTransform = cameraTransform
    }
    
}
