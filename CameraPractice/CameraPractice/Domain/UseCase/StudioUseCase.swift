//
//  CameraUseCase.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import AVFoundation
import Photos
import UIKit

protocol StudioUseCase {
    func checkDeviceAccessAuthorizationStatus(completion: @escaping (Bool) -> Void)
    func checkPhotoAlbumAccessAuthorizationStatus(completion: @escaping (Bool) -> Void)
    func capturePhoto(photoSettings: AVCapturePhotoSettings, photoOutput: AVCapturePhotoOutput)
    func startRecord(movieFileOutput: AVCaptureMovieFileOutput, recorder: some AVCaptureFileOutputRecordingDelegate, deviceOrientation: AVCaptureVideoOrientation)
    func stopRecord(movieFileOutput: AVCaptureMovieFileOutput)
    func saveRecordedMovie()
}

final class DefaultStudioUseCase {
    
    private let cameraRepository: StudioRepository
    private let authorizationManager: AuthorizationManager
    private var inProgressPhotoCaptureDelegates: [Int64: PhotoCaptureProcessor]
    private var outputUrl: URL?
    
    init(cameraRepository: StudioRepository, authorizationManager: AuthorizationManager, inProgressPhotoCaptureDelegates: [Int64: PhotoCaptureProcessor]) {
        self.cameraRepository = cameraRepository
        self.authorizationManager = authorizationManager
        self.inProgressPhotoCaptureDelegates = inProgressPhotoCaptureDelegates
    }
    
}

extension DefaultStudioUseCase: StudioUseCase {
    
    func checkDeviceAccessAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        self.authorizationManager.checkDeviceAuthorization { isAuthorized in
            switch isAuthorized {
            case true:
                completion(true)
            case false:
                self.requestForDeviceAccess { isAuthorized in
                    switch isAuthorized {
                    case true:
                        completion(true)
                    case false:
                        completion(false)
                    }
                }
            }
        }
    }
    
    func checkPhotoAlbumAccessAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        self.authorizationManager.checkPhotoAlbumAuthorization { isAuthorized in
            switch isAuthorized {
            case true:
                completion(true)
            case false:
                self.requestForPhotoAlbumAccess { isAuthorized in
                    switch isAuthorized {
                    case true:
                        completion(true)
                    case false:
                        completion(false)
                    }
                }
            }
        }
    }
    
    func capturePhoto(photoSettings: AVCapturePhotoSettings, photoOutput: AVCapturePhotoOutput) {
        let photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings) { photoCaptureProcessor in
            DispatchQueue.main.async {
                self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
            }
        }
        
        self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
        
        photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
    }
    
    /* MARK: - Available from Swift 5.7
     same
     func startRecord(deviceInput: AVCaptureDeviceInput, recorder: some AVCaptureFileOutputRecordingDelegate, deviceOrientation: AVCaptureVideoOrientation) { ... }
     func startRecord<T>(deviceInput: AVCaptureDeviceInput, recorder: T, deviceOrientation: AVCaptureVideoOrientation) where T: AVCaptureFileOutputRecordingDelegate { ... }
     */
    
    func startRecord(movieFileOutput: AVCaptureMovieFileOutput, recorder: some AVCaptureFileOutputRecordingDelegate, deviceOrientation: AVCaptureVideoOrientation) {
        self.outputUrl = self.generateUrl()
        guard let outputUrl = self.outputUrl else { return }
        movieFileOutput.startRecording(to: outputUrl, recordingDelegate: recorder)
    }
    
    func stopRecord(movieFileOutput: AVCaptureMovieFileOutput) {
        if movieFileOutput.isRecording {
            movieFileOutput.stopRecording()
        }
    }
    
    func saveRecordedMovie() {
        guard let outputUrl = self.outputUrl else { return }
        let recordedMovieUrl = outputUrl as URL
        UISaveVideoAtPathToSavedPhotosAlbum(recordedMovieUrl.path, nil, nil, nil)
    }
    
}

extension DefaultStudioUseCase {
    
    private func requestForDeviceAccess(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { isAuthorized in
            if !isAuthorized {
                completion(false)
            } else {
                completion(true)
            }
        })
    }
    
    private func requestForPhotoAlbumAccess(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { authorizationStatus in
            switch authorizationStatus {
            case .authorized:
                completion(true)
            default:
                completion(false)
            }
        }
    }
    
    private func generateUrl() -> URL? {
        let directory = NSTemporaryDirectory() as NSString
        
        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }
        
        return nil
    }
    
}