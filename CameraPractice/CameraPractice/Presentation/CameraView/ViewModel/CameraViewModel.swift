//
//  CameraViewModel.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import Foundation

protocol CameraViewModel {
    var isAuthorized: Observable<Bool?> { get }

    func didPressTakePhotoButton(previewView: PreviewView)
    func checkIsAuthorized()
}

class DefaultCameraViewModel: CameraViewModel {
    
    private let cameraUseCase: CameraUseCase
    
    let isAuthorized: Observable<Bool?>
    
    init(cameraUseCase: CameraUseCase) {
        self.cameraUseCase = cameraUseCase
        self.isAuthorized = Observable(nil)
    }
    
    func didPressTakePhotoButton(previewView: PreviewView) {
        self.cameraUseCase.executeTakePhoto(previewView: previewView)
    }
    
    func checkIsAuthorized() {
        self.cameraUseCase.executeCheckAuthorization { isAuthorized in
            switch isAuthorized {
            case true:
                self.isAuthorized.value = true
            case false:
                self.isAuthorized.value = false
            }
        }
    }
    
}
