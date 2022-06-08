//
//  AppDIContainer.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import AVFoundation

final class AppDIContainer {
    
//    lazy var apiDataTransferService: DataTransferService = {
//        let apiDataNetwork = DefaultNetworkService()
//        return DefaultDataTransferService(networkService: apiDataNetwork)
//    }()
    
    lazy var authorizationManager: AuthorizationManager = {
        return DefaultAuthorizationManager()
    }()
    
    lazy var studioConfiguration: StudioConfigurable = {
        let cameraDeviceConfiguration: DeviceConfigurable = DefaultDeviceConfiguration()
        let photoSettings: AVCapturePhotoSettings = AVCapturePhotoSettings()
        return DefaultStudioConfiguration(deviceConfiguration: cameraDeviceConfiguration, photoSettings: photoSettings)
    }()
    
    lazy var inProgressPhotoCaptureDelegates: [Int64 : PhotoCaptureProcessor] = {
       return [Int64 : PhotoCaptureProcessor]()
    }()
    
    func makeSceneDIContainer() -> SceneDIContainer {
        let dependencies = SceneDIContainer.Dependencies(authorizationManager: authorizationManager, studioConfiguration: studioConfiguration, inProgressPhotoCaptureDelegates: inProgressPhotoCaptureDelegates)
        return SceneDIContainer(dependencies: dependencies)
    }
    
}
