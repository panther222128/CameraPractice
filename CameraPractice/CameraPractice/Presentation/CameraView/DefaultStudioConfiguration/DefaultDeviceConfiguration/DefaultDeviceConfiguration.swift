//
//  CameraDiviceConfiguration.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/30.
//

import AVFoundation

protocol DeviceConfigurable: CameraDeviceConfigurable & AudioDeviceConfigurable {
    var defaultDevice: AVCaptureDevice? { get }
    dynamic var deviceInput: AVCaptureDeviceInput! { get }
}

protocol CameraDeviceConfigurable {
    func isDeviceFlashAvailable() -> Bool
    func configureCameraDevice(captureSession: AVCaptureSession, cameraDevices: CameraDevices)
}

protocol AudioDeviceConfigurable {
    func configureAudioDevice(captureSession: AVCaptureSession)
}

enum CameraDevices {
    case builtInDualWideCamera
    case frontCamera
}

final class DefaultDeviceConfiguration: DeviceConfigurable {
    
    var defaultDevice: AVCaptureDevice?
    @objc dynamic var deviceInput: AVCaptureDeviceInput!
    
    init() {
        self.defaultDevice = nil
    }
    
    func isDeviceFlashAvailable() -> Bool {
        return self.deviceInput.device.isFlashAvailable
    }
    
}

// MARK: - Camera device configuration

extension DefaultDeviceConfiguration: CameraDeviceConfigurable {
    
    func configureCameraDevice(captureSession: AVCaptureSession, cameraDevices: CameraDevices) {
        do {
            switch cameraDevices {
            case .builtInDualWideCamera:
                if let dualCameraDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                    self.defaultDevice = dualCameraDevice
                }
            case .frontCamera:
                let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTelephotoCamera, .builtInDualWideCamera], mediaType: .video, position: .front)
                guard let frontCameraDevice = discoverySession.devices.filter( { $0.position == .front } ).first else { return }
                self.defaultDevice = frontCameraDevice
            }
            
            guard let defaultDevice = defaultDevice else {
                captureSession.commitConfiguration()
                return
            }
            
            let deviceInput = try AVCaptureDeviceInput(device: defaultDevice)
            
            if captureSession.canAddInput(deviceInput) {
                self.deviceInput = deviceInput
                captureSession.addInput(deviceInput)
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
