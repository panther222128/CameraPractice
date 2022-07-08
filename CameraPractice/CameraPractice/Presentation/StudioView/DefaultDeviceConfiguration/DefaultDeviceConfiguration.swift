//
//  CameraDiviceConfiguration.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/30.
//

import AVFoundation

protocol DeviceConfigurable: CameraDeviceConfigurable & AudioDeviceConfigurable {
    var defaultDevice: AVCaptureDevice? { get }
    var audioDeviceInput: AVCaptureDeviceInput? { get }
    var videoDeviceInput: AVCaptureDeviceInput? { get }
}

protocol CameraDeviceConfigurable {
    func configureCameraDevice(cameraDevices: CameraDevices, videoDataOutput: AVCaptureVideoDataOutput)
}

protocol AudioDeviceConfigurable {
    func configureAudioDevice(audioDataOutput: AVCaptureAudioDataOutput)
}

enum CameraDevices {
    case builtInDualWideCamera
    case frontCamera
}

final class DefaultDeviceConfiguration: DeviceConfigurable {
    
    var defaultDevice: AVCaptureDevice?
    @objc dynamic var audioDeviceInput: AVCaptureDeviceInput?
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput?
    
    init() {
        self.defaultDevice = nil
        self.audioDeviceInput = nil
        self.videoDeviceInput = nil
    }

}

// MARK: - Camera device configuration

extension DefaultDeviceConfiguration: CameraDeviceConfigurable {
    
    func configureCameraDevice(cameraDevices: CameraDevices, videoDataOutput: AVCaptureVideoDataOutput) {
        self.defaultDevice = nil
        self.videoDeviceInput = nil
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
            
            self.videoDeviceInput = try AVCaptureDeviceInput(device: defaultDevice)
        } catch {
            return
        }
    }
    
}

// MARK: - Audio device configuration

extension DefaultDeviceConfiguration: AudioDeviceConfigurable {
    
    func configureAudioDevice(audioDataOutput: AVCaptureAudioDataOutput) {
        self.defaultDevice = nil
        self.audioDeviceInput = nil
        do {
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else { return }
            
            self.audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
        } catch {
            print("Could not create audio device input: \(error)")
        }
    }
    
}
