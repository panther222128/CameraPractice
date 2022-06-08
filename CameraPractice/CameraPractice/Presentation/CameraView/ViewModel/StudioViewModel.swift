//
//  CameraViewModel.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import Foundation
import AVFoundation

protocol StudioViewModel {
    var isDeviceAccessAuthorized: Observable<Bool?> { get }
    var isPhotoAlbumAccessAuthorized: Observable<Bool?> { get }

    func didCheckIsDeviceAccessAuthorized()
    func didCheckIsPhotoAlbumAccessAuthorized()
    func didCapturePhoto(photoSettings: AVCapturePhotoSettings, photoOutput: AVCapturePhotoOutput)
    func didStartRecord<T>(deviceInput: AVCaptureDeviceInput, recorder: T, deviceOrientation: AVCaptureVideoOrientation) where T: AVCaptureFileOutputRecordingDelegate
    func didStopRecord()
    func didSaveRecordedMovie()
}

class DefaultStudioViewModel: StudioViewModel {
    
    private let studioUseCase: StudioUseCase
    
    let isDeviceAccessAuthorized: Observable<Bool?>
    let isPhotoAlbumAccessAuthorized: Observable<Bool?>
    
    init(studioUseCase: StudioUseCase) {
        self.studioUseCase = studioUseCase
        self.isDeviceAccessAuthorized = Observable(nil)
        self.isPhotoAlbumAccessAuthorized = Observable(nil)
    }
    
    func didCheckIsDeviceAccessAuthorized() {
        self.studioUseCase.checkDeviceAccessAuthorizationStatus { isAuthorized in
            switch isAuthorized {
            case true:
                self.isDeviceAccessAuthorized.value = true
            case false:
                self.isDeviceAccessAuthorized.value = false
            }
        }
    }
    
    func didCheckIsPhotoAlbumAccessAuthorized() {
        self.studioUseCase.checkPhotoAlbumAccessAuthorizationStatus { isAuthorized in
            switch isAuthorized {
            case true:
                self.isPhotoAlbumAccessAuthorized.value = true
            case false:
                self.isPhotoAlbumAccessAuthorized.value = false
            }
        }
    }
    
    func didCapturePhoto(photoSettings: AVCapturePhotoSettings, photoOutput: AVCapturePhotoOutput) {
        self.studioUseCase.capturePhoto(photoSettings: photoSettings, photoOutput: photoOutput)
    }
    
    func didStartRecord<T>(deviceInput: AVCaptureDeviceInput, recorder: T, deviceOrientation: AVCaptureVideoOrientation) where T: AVCaptureFileOutputRecordingDelegate {
        self.studioUseCase.startRecord(deviceInput: deviceInput, recorder: recorder, deviceOrientation: deviceOrientation)
    }
    
    func didStopRecord() {
        self.studioUseCase.stopRecord()
    }
    
    func didSaveRecordedMovie() {
        self.studioUseCase.saveRecordedMovie()
    }
    
}
