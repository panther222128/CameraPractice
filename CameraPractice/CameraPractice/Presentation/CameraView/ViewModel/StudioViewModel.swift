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
    func didPressTakePhotoButton(photoSettings: AVCapturePhotoSettings, photoOutput: AVCapturePhotoOutput)
    func didPressRecordStartButton(movieDataOutput: AVCaptureMovieFileOutput, recorder: some AVCaptureFileOutputRecordingDelegate, deviceOrientation: AVCaptureVideoOrientation)
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
    
    func didPressTakePhotoButton(photoSettings: AVCapturePhotoSettings, photoOutput: AVCapturePhotoOutput) {
        self.studioUseCase.capturePhoto(photoSettings: photoSettings, photoOutput: photoOutput)
    }
    
    func didPressRecordStartButton(movieDataOutput: AVCaptureMovieFileOutput, recorder: some AVCaptureFileOutputRecordingDelegate, deviceOrientation: AVCaptureVideoOrientation) {
        self.studioUseCase.startRecord(movieFileOutput: movieDataOutput, recorder: recorder, deviceOrientation: deviceOrientation)
    }
    
    func didPressRecordStopButton(movieFileOutput: AVCaptureMovieFileOutput) {
        self.studioUseCase.stopRecord(movieFileOutput: movieFileOutput)
    }
    
    func didSaveRecordedMovie() {
        self.studioUseCase.saveRecordedMovie()
    }
    
}
