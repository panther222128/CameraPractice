//
//  CameraViewModel.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import Foundation
import AVFoundation

struct StudioViewModelAction {
    let presentMediaPickerView: (() -> Void)
}

protocol StudioViewModel {
    var isDeviceAccessAuthorized: Observable<Bool?> { get }
    var isPhotoAlbumAccessAuthorized: Observable<Bool?> { get }
    var isError: Observable<Bool?> { get }
    var error: Observable<Error?> { get }
    
    func checkDeviceAccessAuthorizationStatus()
    func checkPhotoAlbumAccessAuthorized()
    
    func didPressTakePhotoButton(photoSettings: AVCapturePhotoSettings, photoOutput: AVCapturePhotoOutput)

    func didPressPresentMediaPickerViewButton()
    
    func recordVideo(sampleBuffer: CMSampleBuffer)
    func recordAudio(sampleBuffer: CMSampleBuffer)
    func didPressRecordStartButton(videoTransform: CGAffineTransform, videoDataOutput: AVCaptureVideoDataOutput, audioDataOutput: AVCaptureAudioDataOutput)
    func didPressRecordStopButton(completion: @escaping (URL) -> Void)
    func saveMovie(outputUrl: URL)
}

class DefaultStudioViewModel: StudioViewModel {

    private let studioUseCase: StudioUseCase
    private let action: StudioViewModelAction
    
    let isDeviceAccessAuthorized: Observable<Bool?>
    let isPhotoAlbumAccessAuthorized: Observable<Bool?>
    let isError: Observable<Bool?>
    let error: Observable<Error?>
    
    init(studioUseCase: StudioUseCase, action: StudioViewModelAction) {
        self.studioUseCase = studioUseCase
        self.isDeviceAccessAuthorized = Observable(nil)
        self.isPhotoAlbumAccessAuthorized = Observable(nil)
        self.isError = Observable(nil)
        self.error = Observable(nil)
        self.action = action
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
    
    func didPressPresentMediaPickerViewButton() {
        self.action.presentMediaPickerView()
    }
    
    func recordVideo(sampleBuffer: CMSampleBuffer) {
        self.studioUseCase.recordVideo(sampleBuffer: sampleBuffer)
    }
    
    func recordAudio(sampleBuffer: CMSampleBuffer) {
        self.studioUseCase.recordAudio(sampleBuffer: sampleBuffer)
    }
    
    func didPressRecordStartButton(videoTransform: CGAffineTransform, videoDataOutput: AVCaptureVideoDataOutput, audioDataOutput: AVCaptureAudioDataOutput) {
        self.studioUseCase.startRecording(videoTransform: videoTransform, videoDataOutput: videoDataOutput, audioDataOutput: audioDataOutput)
    }
    
    func didPressRecordStopButton(completion: @escaping (URL) -> Void) {
        self.studioUseCase.stopRecording(completion: completion)
    }
    
    func saveMovie(outputUrl: URL) {
        self.studioUseCase.saveMovie(outputUrl: outputUrl)
    }
    
}
