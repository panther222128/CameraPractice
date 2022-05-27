//
//  CameraUseCase.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import Foundation

protocol CameraUseCase {
}

final class DefaultCameraUseCase: CameraUseCase {
    
    private let cameraRepository: CameraRepository
    private let authorizationManager: AuthorizationManager
    
    init(cameraRepository: CameraRepository, authorizationManager: AuthorizationManager) {
        self.cameraRepository = cameraRepository
        self.authorizationManager = authorizationManager
    }
    
}
