//
//  AuthorizationManager.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import AVFoundation

// MARK: - UseCase, AuthorizationManager의 책임, 역할 명확히 해야 함.

protocol AuthorizationManager {
    func checkAuthorization()
    func requestAccess()
}

final class DefaultAuthorizationManager: AuthorizationManager {

    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return
        default:
            self.requestAccess()
        }
    }
    
    func requestAccess() {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
            if !granted {
                
            }
        })
    }
    
}
