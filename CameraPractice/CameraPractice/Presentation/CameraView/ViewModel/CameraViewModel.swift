//
//  CameraViewModel.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import Foundation

protocol CameraViewModel {
    var isDeviceAccessAuthorized: Observable<Bool?> { get }
    var isPhotoAlbumAccessAuthorized: Observable<Bool?> { get }

    func didPressTakePhotoButton()
    func didCheckIsDeviceAccessAuthorized()
    func didCheckIsPhotoAlbumAccessAuthorized()
}

class DefaultCameraViewModel: CameraViewModel {
    
    private let cameraUseCase: CameraUseCase
    
    let isDeviceAccessAuthorized: Observable<Bool?>
    let isPhotoAlbumAccessAuthorized: Observable<Bool?>
    
    init(cameraUseCase: CameraUseCase) {
        self.cameraUseCase = cameraUseCase
        self.isDeviceAccessAuthorized = Observable(nil)
        self.isPhotoAlbumAccessAuthorized = Observable(nil)
    }
    
    func didPressTakePhotoButton() {
        
    }

    func didCheckIsDeviceAccessAuthorized() {
        self.cameraUseCase.checkDeviceAccessAuthorizationStatus { isAuthorized in
            switch isAuthorized {
            case true:
                self.isDeviceAccessAuthorized.value = true
            case false:
                self.isDeviceAccessAuthorized.value = false
            }
        }
    }
    
    func didCheckIsPhotoAlbumAccessAuthorized() {
        self.cameraUseCase.checkPhotoAlbumAccessAuthorizationStatus { isAuthorized in
            switch isAuthorized {
            case true:
                self.isPhotoAlbumAccessAuthorized.value = true
            case false:
                self.isPhotoAlbumAccessAuthorized.value = false
            }
        }
    }
    
}
