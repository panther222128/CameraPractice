//
//  CameraViewModel.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import Foundation
import AVFoundation

protocol CameraViewModel {
    var isDeviceAccessAuthorized: Observable<Bool?> { get }
    var isPhotoAlbumAccessAuthorized: Observable<Bool?> { get }

    func didCheckIsDeviceAccessAuthorized()
    func didCheckIsPhotoAlbumAccessAuthorized()
    func didCapturePhoto(photoSettings: AVCapturePhotoSettings, photoOutput: AVCapturePhotoOutput)
    func didStartRecord<T>(deviceInput: AVCaptureDeviceInput, recorder: T) where T: AVCaptureFileOutputRecordingDelegate
    func didStopRecord()
}

class DefaultCameraViewModel: CameraViewModel {
    
    private let cameraUseCase: CameraUseCase
    
    let isDeviceAccessAuthorized: Observable<Bool?>
    let isPhotoAlbumAccessAuthorized: Observable<Bool?>
    
    init(cameraUseCase: CameraUseCase) {
        self.cameraUseCase = cameraUseCase
        self.isDeviceAccessAuthorized = Observable(nil)
        self.isPhotoAlbumAccessAuthorized = Observable(nil)
    }
    
    func didCheckIsDeviceAccessAuthorized() {
        self.cameraUseCase.checkDeviceAccessAuthorizationStatus { isAuthorized in
            switch isAuthorized {
            case true:
                self.isDeviceAccessAuthorized.value = true
            case false:
                self.isDeviceAccessAuthorized.value = false
            }
        }
    }
    
    func didCheckIsPhotoAlbumAccessAuthorized() {
        self.cameraUseCase.checkPhotoAlbumAccessAuthorizationStatus { isAuthorized in
            switch isAuthorized {
            case true:
                self.isPhotoAlbumAccessAuthorized.value = true
            case false:
                self.isPhotoAlbumAccessAuthorized.value = false
            }
        }
    }
    
    func didCapturePhoto(photoSettings: AVCapturePhotoSettings, photoOutput: AVCapturePhotoOutput) {
        self.cameraUseCase.capturePhoto(photoSettings: photoSettings, photoOutput: photoOutput)
    }
    
    func didStartRecord<T>(deviceInput: AVCaptureDeviceInput, recorder: T) where T: AVCaptureFileOutputRecordingDelegate {
        self.cameraUseCase.startRecord(deviceInput: deviceInput, recorder: recorder)
    }
    
    func didStopRecord() {
        self.cameraUseCase.stopRecord()
    }
    
}
