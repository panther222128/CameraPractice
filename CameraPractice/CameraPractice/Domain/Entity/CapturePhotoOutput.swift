//
//  CapturePhotoOutput.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/30.
//

import AVFoundation

final class CapturePhotoOutput: AVCapturePhotoOutput {
    
    override init() {
        super.init()
        self.isHighResolutionCaptureEnabled = true
        self.isLivePhotoCaptureEnabled = isLivePhotoCaptureSupported
        self.isDepthDataDeliveryEnabled = isDepthDataDeliverySupported
        self.isPortraitEffectsMatteDeliveryEnabled = isPortraitEffectsMatteDeliverySupported
        self.enabledSemanticSegmentationMatteTypes = availableSemanticSegmentationMatteTypes
    }
    
}
