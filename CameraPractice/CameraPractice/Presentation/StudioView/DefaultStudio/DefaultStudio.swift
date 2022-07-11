//
//  CameraService.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/29.
//

import AVFoundation
import UIKit

enum CameraPosition {
    case back
    case front
}

protocol StudioConfigurable {
    var photoSettings: AVCapturePhotoSettings? { get }
    var photoOutput: AVCapturePhotoOutput? { get }
    var videoDataOutput: AVCaptureVideoDataOutput { get }
    var audioDataOutput: AVCaptureAudioDataOutput { get }
    var videoTransform: CGAffineTransform? { get }
    
    func configureEnvironment<T>(at index: Int, presenter: T,with camera: CameraDevices,  sessionQueue: DispatchQueue) where T: UIViewController & DataOutputSampleBufferDelegate
    func configurePhotoInputOutput<T>(presenter: T, with camera: CameraDevices, sessionQueue: DispatchQueue) where T: UIViewController & DataOutputSampleBufferDelegate
    func configureMovieInputOutput<T>(presenter: T, with camera: CameraDevices, sessionQueue: DispatchQueue) where T: UIViewController & DataOutputSampleBufferDelegate
    func convertCamera<T>(to camera: CameraDevices, presenter: T, sessionQueue: DispatchQueue) where T: UIViewController & DataOutputSampleBufferDelegate
    
    func createVideoTransform(videoDataOutput: AVCaptureVideoDataOutput)
    
    func invalidateStudio()
}

final class DefaultStudio: StudioConfigurable {
    
    private let deviceConfiguration: DeviceConfigurable
    
    var photoSettings: AVCapturePhotoSettings?
    var photoOutput: AVCapturePhotoOutput?
    var videoDataOutput: AVCaptureVideoDataOutput
    var audioDataOutput: AVCaptureAudioDataOutput
    var videoTransform: CGAffineTransform?
    
    private let captureSession: AVCaptureSession
    
    init(deviceConfiguration: DeviceConfigurable, photoSettings: AVCapturePhotoSettings) {
        self.captureSession = AVCaptureSession()
        self.deviceConfiguration = deviceConfiguration
        self.photoSettings = photoSettings
        self.videoTransform = nil
        self.captureSession.startRunning()
        self.videoDataOutput = AVCaptureVideoDataOutput()
        self.audioDataOutput = AVCaptureAudioDataOutput()
    }
    
    func configureEnvironment<T>(at index: Int, presenter: T, with cameraDevices: CameraDevices, sessionQueue: DispatchQueue) where T: UIViewController & DataOutputSampleBufferDelegate {
        switch index {
        case 0:
            self.configurePhotoInputOutput(presenter: presenter, with: cameraDevices, sessionQueue: sessionQueue)
        case 1:
            self.configureMovieInputOutput(presenter: presenter, with: cameraDevices, sessionQueue: sessionQueue)
        default:
            self.configurePhotoInputOutput(presenter: presenter, with: cameraDevices, sessionQueue: sessionQueue)
        }
    }
    
    /* MARK: - Available from Swift 5.7
     same
     func configurePhotoInputOutput<T>(presenter: T) where T: UIViewController & DataOutputSampleBufferDelegate { ... }
     func configurePhotoInputOutput(presenter: some UIViewController & DataOutputSampleBufferDelegate) { ... }
     */
    
    func configurePhotoInputOutput<T>(presenter: T, with camera: CameraDevices, sessionQueue: DispatchQueue) where T: UIViewController & DataOutputSampleBufferDelegate {
        self.configureSession()
        self.configureCameraDevice(cameraDevices: .builtInDualWideCamera)
        self.configureAudioDevice()
        self.addVideoDeviceInput()
        self.addAudioDeviceInput()
        self.configurePhotoOutput()
        self.configurePhotoSettings()
        self.configureAudioDataOutput(presenter: presenter, sessionQueue: sessionQueue)
        self.configureVideoDataOutput(presenter: presenter, sessionQueue: sessionQueue)
    }
    
    func configureMovieInputOutput<T>(presenter: T, with camera: CameraDevices, sessionQueue: DispatchQueue) where T: UIViewController & DataOutputSampleBufferDelegate {
        self.configureSession()
        self.configureCameraDevice(cameraDevices: .builtInDualWideCamera)
        self.configureAudioDevice()
        self.addVideoDeviceInput()
        self.addAudioDeviceInput()
        self.configureAudioDataOutput(presenter: presenter, sessionQueue: sessionQueue)
        self.configureVideoDataOutput(presenter: presenter, sessionQueue: sessionQueue)
    }
    
    func convertCamera<T>(to camera: CameraDevices, presenter: T, sessionQueue: DispatchQueue) where T: UIViewController & DataOutputSampleBufferDelegate {
        guard let videoDeviceInput = self.deviceConfiguration.videoDeviceInput else { return }
        switch videoDeviceInput.device.position {
        case .back:
            guard let deviceInput = self.deviceConfiguration.videoDeviceInput else { return }
            self.captureSession.removeInput(deviceInput)
            guard let photoOutput = photoOutput else { return }
            self.captureSession.removeOutput(photoOutput)
            self.deviceConfiguration.configureCameraDevice(cameraDevices: .frontCamera, videoDataOutput: self.videoDataOutput)
            self.captureSession.beginConfiguration()
            defer {
                self.captureSession.commitConfiguration()
            }
            self.addVideoDeviceInput()
            self.addAudioDeviceInput()
            self.configurePhotoOutput()
            self.configurePhotoSettings()
            self.configureVideoDataOutput(presenter: presenter, sessionQueue: sessionQueue)
            self.configureAudioDataOutput(presenter: presenter, sessionQueue: sessionQueue)
            guard let deviceInput = self.deviceConfiguration.videoDeviceInput else { return }
            guard let frontDeviceInput = self.deviceConfiguration.videoDeviceInput else { return }
            guard let deviceInputPort = deviceInput.ports(for: .video, sourceDeviceType: frontDeviceInput.device.deviceType, sourceDevicePosition: frontDeviceInput.device.position).first else { return }
            let connection = AVCaptureConnection(inputPorts: [deviceInputPort], output: self.videoDataOutput)
            if self.captureSession.canAddConnection(connection) {
                self.captureSession.addConnection(connection)
            }
        case .front:
            guard let deviceInput = self.deviceConfiguration.videoDeviceInput else { return }
            self.captureSession.removeInput(deviceInput)
            guard let photoOutput = photoOutput else { return }
            self.captureSession.removeOutput(photoOutput)
            self.deviceConfiguration.configureCameraDevice(cameraDevices: .builtInDualWideCamera, videoDataOutput: self.videoDataOutput)
            self.captureSession.beginConfiguration()
            defer {
                self.captureSession.commitConfiguration()
            }
            self.addVideoDeviceInput()
            self.addAudioDeviceInput()
            self.configurePhotoOutput()
            self.configurePhotoSettings()
            self.configureVideoDataOutput(presenter: presenter, sessionQueue: sessionQueue)
            self.configureAudioDataOutput(presenter: presenter, sessionQueue: sessionQueue)
        case .unspecified:
            guard let deviceInput = self.deviceConfiguration.videoDeviceInput else { return }
            self.captureSession.removeInput(deviceInput)
            guard let photoOutput = photoOutput else { return }
            self.captureSession.removeOutput(photoOutput)
            self.deviceConfiguration.configureCameraDevice(cameraDevices: .frontCamera, videoDataOutput: self.videoDataOutput)
            self.captureSession.beginConfiguration()
            defer {
                self.captureSession.commitConfiguration()
            }
            self.addVideoDeviceInput()
            self.addAudioDeviceInput()
            self.configurePhotoOutput()
            self.configurePhotoSettings()
            self.configureVideoDataOutput(presenter: presenter, sessionQueue: sessionQueue)
            self.configureAudioDataOutput(presenter: presenter, sessionQueue: sessionQueue)
        @unknown default:
            fatalError("FATAL")
        }
    }
    
    func invalidateStudio() {
        self.stopSession()
        self.photoSettings = nil
        self.photoOutput = nil
    }
    
}

// MARK: - Session

extension DefaultStudio {
    
    private func addAudioDeviceInput() {
        guard let audioDeviceInput = self.deviceConfiguration.audioDeviceInput else { return }
        if self.captureSession.canAddInput(audioDeviceInput) {
            self.captureSession.addInput(audioDeviceInput)
        }
    }
    
    private func addVideoDeviceInput() {
        guard let videoDeviceInput = self.deviceConfiguration.videoDeviceInput else { return }
        if self.captureSession.canAddInput(videoDeviceInput) {
            self.captureSession.addInput(videoDeviceInput)
        }
    }
    
    private func captureSessionBeginConfiguration() {
        self.captureSession.beginConfiguration()
    }
    
    private func configureSession() {
        self.captureSession.beginConfiguration()
        defer {
            self.captureSession.commitConfiguration()
        }
        self.captureSession.sessionPreset = .high
    }
    
    private func stopSession() {
        self.captureSession.stopRunning()
    }
    
}

// MARK: - Device and input, output

extension DefaultStudio {
    
    private func configureCameraDevice(cameraDevices: CameraDevices) {
        self.captureSession.beginConfiguration()
        defer {
            self.captureSession.commitConfiguration()
        }
        self.deviceConfiguration.configureCameraDevice(cameraDevices: cameraDevices, videoDataOutput: self.videoDataOutput)
    }
    
    private func configureAudioDevice() {
        self.captureSession.beginConfiguration()
        defer {
            self.captureSession.commitConfiguration()
        }
        self.deviceConfiguration.configureAudioDevice(audioDataOutput: self.audioDataOutput)
    }

    private func configurePhotoOutput() {
        self.captureSession.beginConfiguration()
        defer {
            self.captureSession.commitConfiguration()
        }
        self.photoOutput = AVCapturePhotoOutput()
        guard let photoOutput = self.photoOutput else { return }
        
        photoOutput.isHighResolutionCaptureEnabled = true
        
        if self.captureSession.canAddOutput(photoOutput) {
            self.captureSession.addOutput(photoOutput)
        }
    }
    
    /* MARK: - Available from Swift 5.7
     same
     private func configureVideoDataOutput<T>(presenter: T) where T: UIViewController & AVCaptureVideoDataOutputSampleBufferDelegate
     private func configureVideoDataOutput(presenter: some UIViewController & AVCaptureVideoDataOutputSampleBufferDelegate)
     */
    
    private func configureVideoDataOutput<T>(presenter: T, sessionQueue: DispatchQueue) where T: UIViewController & AVCaptureVideoDataOutputSampleBufferDelegate {
        self.captureSession.beginConfiguration()
        defer {
            self.captureSession.commitConfiguration()
        }
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        videoDataOutput.setSampleBufferDelegate(presenter, queue: sessionQueue)
        if self.captureSession.canAddOutput(self.videoDataOutput) {
            self.captureSession.addOutput(self.videoDataOutput)
        }
    }
    
    /* MARK: - Available from Swift 5.7
     same
     private func configureAudioDataOutput<T>(presenter: T) where T: UIViewController & AVCaptureVideoDataOutputSampleBufferDelegate
     private func configureAudioDataOutput(presenter: some UIViewController & AVCaptureAudioDataOutputSampleBufferDelegate)
     */
    
    private func configureAudioDataOutput<T>(presenter: T, sessionQueue: DispatchQueue) where T: UIViewController & AVCaptureAudioDataOutputSampleBufferDelegate {
        self.captureSession.beginConfiguration()
        defer {
            self.captureSession.commitConfiguration()
        }
        
        if self.captureSession.canAddOutput(self.audioDataOutput) {
            self.captureSession.addOutput(self.audioDataOutput)
        }
    }
    
}

// MARK: - PhotoSettings

extension DefaultStudio {
    
    private func configurePhotoSettings() {
        guard let photoOutput = self.photoOutput else { return }
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            self.photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
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
