//
//  AuthorizationManager.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import AVFoundation
import Photos

protocol AuthorizationManager {
    func checkDeviceAuthorization(completion: @escaping (Bool) -> Void)
    func checkPhotoAlbumAuthorization(completion: @escaping (Bool) -> Void)
}

final class DefaultAuthorizationManager: AuthorizationManager {
    
    func checkDeviceAuthorization(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        default:
            completion(false)
        }
    }
    
    func checkPhotoAlbumAuthorization(completion: @escaping (Bool) -> Void) {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized:
            completion(true)
        default:
            completion(false)
        }
    }
    
}
