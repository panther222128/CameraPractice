//
//  CameraDiviceConfiguration.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/30.
//

import AVFoundation

protocol DeviceConfigurable: CameraDeviceConfigurable & AudioDeviceConfigurable {
    var defaultVideoDevice: AVCaptureDevice? { get }
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
    
    var defaultVideoDevice: AVCaptureDevice?
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
    
    func configureCameraDevice(captureSession: AVCaptureSession, cameraDevices: CameraDevices) {
        do {
            switch cameraDevices {
            case .builtInDualWideCamera:
                if let dualCameraDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                    self.defaultVideoDevice = dualCameraDevice
                }
            case .frontCamera:
                let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTelephotoCamera, .builtInDualWideCamera], mediaType: .video, position: .front)
                guard let frontCameraDevice = discoverySession.devices.filter( { $0.position == .front } ).first else { return }
                self.defaultVideoDevice = frontCameraDevice
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
