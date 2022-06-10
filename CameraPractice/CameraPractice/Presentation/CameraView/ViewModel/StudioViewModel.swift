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

    func checkDeviceAccessAuthorizationStatus()
    func checkPhotoAlbumAccessAuthorized()
    
    func didPressTakePhotoButton(photoSettings: AVCapturePhotoSettings, photoOutput: AVCapturePhotoOutput)
    func didPressRecordStartButton(movieFileOutput: AVCaptureMovieFileOutput, recorder: some AVCaptureFileOutputRecordingDelegate, deviceOrientation: AVCaptureVideoOrientation)
    func didPressRecordStopButton(movieFileOutput: AVCaptureMovieFileOutput)
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
    
    func checkDeviceAccessAuthorizationStatus() {
        self.studioUseCase.checkDeviceAccessAuthorizationStatus { isAuthorized in
            switch isAuthorized {
            case true:
                self.isDeviceAccessAuthorized.value = true
            case false:
                self.isDeviceAccessAuthorized.value = false
            }
        }
    }
    
    func checkPhotoAlbumAccessAuthorized() {
        self.studioUseCase.checkPhotoAlbumAccessAuthorizationStatus { isAuthorized in
            switch isAuthorized {
            case true:
                self.isPhotoAlbumAccessAuthorized.value = true
            case false:
                self.isPhotoAlbumAccessAuthorized.value = false
            }
        }
    }
    
    func didPressTakePhotoButton(photoSettings: AVCapturePhotoSettings, photoOutput: AVCapturePhotoOutput) {
        self.studioUseCase.capturePhoto(photoSettings: photoSettings, photoOutput: photoOutput)
    }
    
    func didPressRecordStartButton(movieFileOutput: AVCaptureMovieFileOutput, recorder: some AVCaptureFileOutputRecordingDelegate, deviceOrientation: AVCaptureVideoOrientation) {
        self.studioUseCase.startRecord(movieFileOutput: movieFileOutput, recorder: recorder, deviceOrientation: deviceOrientation)
    }
    
    func didPressRecordStopButton(movieFileOutput: AVCaptureMovieFileOutput) {
        self.studioUseCase.stopRecord(movieFileOutput: movieFileOutput)
    }
    
    func didSaveRecordedMovie() {
        self.studioUseCase.saveRecordedMovie()
    }
    
}
