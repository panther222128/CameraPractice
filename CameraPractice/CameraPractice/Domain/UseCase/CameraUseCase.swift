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

final class DefaultCameraUseCase: CameraUseCase {
    
    private let cameraRepository: CameraRepository
    private let authorizationManager: AuthorizationManager
    
    init(cameraRepository: CameraRepository, authorizationManager: AuthorizationManager) {
        self.cameraRepository = cameraRepository
        self.authorizationManager = authorizationManager
    }
    
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
