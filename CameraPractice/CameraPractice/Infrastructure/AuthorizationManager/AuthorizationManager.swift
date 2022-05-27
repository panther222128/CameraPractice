//
//  AuthorizationManager.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import AVFoundation

protocol AuthorizationManager {
    func checkAuthorized()
}

enum SessionSetupResult {
    case success
    case notAuthorized
}

final class DefaultAuthorizationManager: AuthorizationManager {

    func checkAuthorized() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return
        default:
            self.requestAuthorization()
        }
    }
    
    private func requestAuthorization() {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
            if !granted {
                
            } else {
                
            }
        })
    }
    
}
