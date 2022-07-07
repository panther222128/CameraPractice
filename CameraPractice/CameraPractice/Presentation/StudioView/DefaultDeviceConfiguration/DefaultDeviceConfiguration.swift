//
//  CameraDiviceConfiguration.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/30.
//

import AVFoundation

protocol DeviceConfigurable: CameraDeviceConfigurable & AudioDeviceConfigurable {
    var defaultDevice: AVCaptureDevice? { get }
}

protocol CameraDeviceConfigurable {
    func configureCameraDevice(captureSession: AVCaptureSession, cameraDevices: CameraDevices, videoDataOutput: AVCaptureVideoDataOutput)
}

protocol AudioDeviceConfigurable {
    func configureAudioDevice(captureSession: AVCaptureSession, audioDataOutput: AVCaptureAudioDataOutput)
}

enum CameraDevices {
    case builtInDualWideCamera
    case frontCamera
}

final class DefaultDeviceConfiguration: DeviceConfigurable {
    
    var defaultDevice: AVCaptureDevice?
    
    init() {
        self.defaultDevice = nil
    }

}

// MARK: - Camera device configuration

extension DefaultDeviceConfiguration: CameraDeviceConfigurable {
    
    func configureCameraDevice(captureSession: AVCaptureSession, cameraDevices: CameraDevices, videoDataOutput: AVCaptureVideoDataOutput) {
        do {
            switch cameraDevices {
            case .builtInDualWideCamera:
                guard let dualWideCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
                self.defaultDevice = dualWideCamera
            case .frontCamera:
                let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTelephotoCamera, .builtInDualWideCamera], mediaType: .video, position: .front)
                guard let frontCameraDevice = discoverySession.devices.filter( { $0.position == .front } ).first else { return }
                self.defaultDevice = frontCameraDevice
            }
            
            guard let defaultDevice = defaultDevice else {
                return
            }
            
            let deviceInput = try AVCaptureDeviceInput(device: defaultDevice)
            
            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            }
        } catch {
            return
        }
    }
    
}

// MARK: - Audio device configuration

extension DefaultDeviceConfiguration: AudioDeviceConfigurable {
    
    func configureAudioDevice(captureSession: AVCaptureSession, audioDataOutput: AVCaptureAudioDataOutput) {
        do {
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else { return }
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            
            if captureSession.canAddInput(audioDeviceInput) {
                captureSession.addInput(audioDeviceInput)
            } else {
                print("Could not add audio device input to the session")
            }
        } catch {
            print("Could not create audio device input: \(error)")
        }
    }
    
}
