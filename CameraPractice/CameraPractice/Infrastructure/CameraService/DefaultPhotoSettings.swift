//
//  PhotoSetting.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/03.
//

import AVFoundation

final class DefaultPhotoSettings: AVCapturePhotoSettings {
    
    override init() {
        super.init()
        self.isHighResolutionPhotoEnabled = true
    }
    
}
