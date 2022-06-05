//
//  CameraDiviceConfiguration.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/30.
//

import AVFoundation

protocol CameraDeviceConfigurable {
    func isDeviceFlashAvailable() -> Bool
    func configureCameraDevice(captureSession: AVCaptureSession)
}

protocol AudioDeviceConfigurable {
    func configureAudioDevice(captureSession: AVCaptureSession)
}

final class DefaultDeviceConfiguration {
    
    private var defaultVideoDevice: AVCaptureDevice?
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    
    init() {
        self.defaultVideoDevice = nil
    }
    
    func isDeviceFlashAvailable() -> Bool {
        return self.videoDeviceInput.device.isFlashAvailable
    }
    
}

// MARK: - Camera device configuration

extension DefaultDeviceConfiguration: CameraDeviceConfigurable {
    
    func configureCameraDevice(captureSession: AVCaptureSession) {
        do {
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                self.defaultVideoDevice = dualCameraDevice
            } else if let dualWideCameraDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                self.defaultVideoDevice = dualWideCameraDevice
            } else if let builtInWideAngleCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                self.defaultVideoDevice = builtInWideAngleCamera
            } else if let builtInWideAngleCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                self.defaultVideoDevice = builtInWideAngleCamera
            }
            
            guard let videoDevice = defaultVideoDevice else {
                captureSession.commitConfiguration()
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if captureSession.canAddInput(videoDeviceInput) {
                self.videoDeviceInput = videoDeviceInput
                captureSession.addInput(videoDeviceInput)
            }
        } catch {
            captureSession.commitConfiguration()
            return
        }
        captureSession.commitConfiguration()
    }
    
}

// MARK: - Audio device configuration

extension DefaultDeviceConfiguration: AudioDeviceConfigurable {
    
    func configureAudioDevice(captureSession: AVCaptureSession) {
        do {
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
            if captureSession.canAddInput(audioDeviceInput) {
                captureSession.addInput(audioDeviceInput)
            } else {
                print("Could not add audio device input to the session")
            }
        } catch {
            print("Could not create audio device input: \(error)")
        }
        captureSession.commitConfiguration()
    }
    
}
