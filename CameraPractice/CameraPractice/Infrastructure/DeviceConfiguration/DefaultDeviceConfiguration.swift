//
//  CameraDiviceConfiguration.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/30.
//

import AVFoundation

protocol DeviceConfigurable: CameraDeviceConfigurable & AudioDeviceConfigurable {
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
    
    var audioDeviceInput: AVCaptureDeviceInput?
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput?
    
    init() {
        self.audioDeviceInput = nil
        self.videoDeviceInput = nil
    }

}

// MARK: - Camera device configuration

extension DefaultDeviceConfiguration: CameraDeviceConfigurable {
    
    func configureCameraDevice(cameraDevices: CameraDevices, videoDataOutput: AVCaptureVideoDataOutput) {
        do {
            switch cameraDevices {
            case .builtInDualWideCamera:
                guard let dualWideCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
                self.videoDeviceInput = try AVCaptureDeviceInput(device: dualWideCamera)
            case .frontCamera:
                let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTelephotoCamera, .builtInDualWideCamera], mediaType: .video, position: .front)
                guard let frontCamera = discoverySession.devices.first else { return }
                self.videoDeviceInput = try AVCaptureDeviceInput(device: frontCamera)
            }
        } catch {
            return
        }
    }
    
}

// MARK: - Audio device configuration

extension DefaultDeviceConfiguration: AudioDeviceConfigurable {
    
    func configureAudioDevice(audioDataOutput: AVCaptureAudioDataOutput) {
        do {
            guard let microphone = AVCaptureDevice.default(for: .audio) else { return }
            self.audioDeviceInput = try AVCaptureDeviceInput(device: microphone)
        } catch {
            print("Could not create audio device input: \(error)")
        }
    }
    
}
