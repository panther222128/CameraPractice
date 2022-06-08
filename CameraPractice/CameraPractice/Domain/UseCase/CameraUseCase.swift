//
//  CameraUseCase.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import AVFoundation
import Photos

protocol CameraUseCase {
    func checkDeviceAccessAuthorizationStatus(completion: @escaping (Bool) -> Void)
    func checkPhotoAlbumAccessAuthorizationStatus(completion: @escaping (Bool) -> Void)
    func capturePhoto(photoSettings: AVCapturePhotoSettings, photoOutput: AVCapturePhotoOutput)
}

final class DefaultCameraUseCase {
    
    private let cameraRepository: CameraRepository
    private let authorizationManager: AuthorizationManager
    private var inProgressPhotoCaptureDelegates: [Int64: PhotoCaptureProcessor]
    
    init(cameraRepository: CameraRepository, authorizationManager: AuthorizationManager, inProgressPhotoCaptureDelegates: [Int64: PhotoCaptureProcessor]) {
        self.cameraRepository = cameraRepository
        self.authorizationManager = authorizationManager
        self.inProgressPhotoCaptureDelegates = inProgressPhotoCaptureDelegates
    }
    
}

extension DefaultCameraUseCase: CameraUseCase {
    
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

}

extension DefaultCameraUseCase {
    
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
    
}
