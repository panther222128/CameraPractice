//
//  CameraUseCase.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import AVFoundation

protocol CameraUseCase {
    func excuteCheckAuthorization(completion: @escaping (Bool) -> Void)
}

final class DefaultCameraUseCase {
    
    private let cameraRepository: CameraRepository
    private let authorizationManager: AuthorizationManager
    private let cameraService: CameraService
    
    init(cameraRepository: CameraRepository, authorizationManager: AuthorizationManager, cameraService: CameraService) {
        self.cameraRepository = cameraRepository
        self.authorizationManager = authorizationManager
        self.cameraService = cameraService
    }
    
}

extension DefaultCameraUseCase: CameraUseCase {
    
    func excuteCheckAuthorization(completion: @escaping (Bool) -> Void) {
        self.authorizationManager.checkAuthorization { isAuthorized in
            switch isAuthorized {
            case true:
                completion(true)
            case false:
                self.requestAccess { isAuthorized in
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
    
    func excecuteSetUpCamera() {
        self.cameraService.configureSession()
        self.cameraService.configureCameraDivce( )
        self.cameraService.configureAudioDevice()
        self.cameraService.configureCameraDivcePhotoOutput()
//        self.cameraService.configurePreviewSession()
    }
    
}

extension DefaultCameraUseCase {
    
    private func requestAccess(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { isAuthorized in
            if !isAuthorized {
                completion(false)
            } else {
                completion(true)
            }
        })
    }
    
}
