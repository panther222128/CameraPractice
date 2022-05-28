//
//  AuthorizationManager.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import AVFoundation

protocol AuthorizationManager {
    func checkAuthorization(completion: @escaping (Bool) -> Void)
}

final class DefaultAuthorizationManager: AuthorizationManager {

    func checkAuthorization(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        default:
            completion(false)
        }
    }
    
}
