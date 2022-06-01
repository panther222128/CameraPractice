//
//  CameraService.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/29.
//

import AVFoundation

protocol CameraService {
    func configureSession()
    func configureCameraDevice()
    func configureAudioDevice()
    func configureCameraDevicePhotoOutput()
//    func configurePreviewSession()
}

final class DefaultCameraSerivce: CameraService {
    
    private var captureSession: AVCaptureSession?
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    // MARK: - Photo input, output
    private let photoOutput = AVCapturePhotoOutput()
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    
    init() {
        self.captureSession = nil
    }
    
    // Session
    func configureSession() {
        self.captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
    }
    
    // Photo input
    func configureCameraDevice() {
        guard let captureSession = captureSession else { return }
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let dualWideCameraDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                defaultVideoDevice = dualWideCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                defaultVideoDevice = frontCameraDevice
            }
            
            guard let videoDevice = defaultVideoDevice else {
                captureSession.commitConfiguration()
                return
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
//                DispatchQueue.main.async {
//                    let initialVideoOrientation: AVCaptureVideoOrientation = .portrait
//                    previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
//                }
            } else {
                captureSession.commitConfiguration()
                return
            }
        } catch {
            captureSession.commitConfiguration()
            return
        }
    }
    
    func configureAudioDevice() {
        guard let captureSession = captureSession else { return }
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
    }
    
    // MARK: - Photo output
    func configureCameraDevicePhotoOutput() {
        guard let captureSession = captureSession else { return }
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            
            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
            photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported
            photoOutput.isPortraitEffectsMatteDeliveryEnabled = photoOutput.isPortraitEffectsMatteDeliverySupported
            photoOutput.enabledSemanticSegmentationMatteTypes = photoOutput.availableSemanticSegmentationMatteTypes
        } else {
            captureSession.commitConfiguration()
            return
        }
        captureSession.commitConfiguration()
    }
    
//    func configurePreviewSession() {
//        previewView.session = captureSession
//    }
    
}
