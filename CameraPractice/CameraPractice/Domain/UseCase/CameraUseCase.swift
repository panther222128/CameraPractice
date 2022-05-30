//
//  CameraUseCase.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import AVFoundation

protocol CameraUseCase {
    func executeCheckAuthorization(completion: @escaping (Bool) -> Void)
    func setUpCamera(previewView: PreviewView)
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
    
    func executeCheckAuthorization(completion: @escaping (Bool) -> Void) {
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
    
    func setUpCamera(previewView: PreviewView) {
        DispatchQueue.main.async {
            self.cameraService.startSession()
            self.cameraService.applyPreviewView(previewView: previewView)
            self.cameraService.configureSession()
        }
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
