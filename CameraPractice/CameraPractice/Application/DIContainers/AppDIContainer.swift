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
    
    lazy var cameraService: CameraService = {
        let cameraDeviceConfiguration: DeviceConfigurable = DefaultDeviceConfiguration()
        let photoSettings: AVCapturePhotoSettings = AVCapturePhotoSettings()
        let inProgressPhotoCaptureDelegates: [Int64 : PhotoCaptureProcessor] = [Int64 : PhotoCaptureProcessor]()
        return DefaultCameraSerivce(deviceConfiguration: cameraDeviceConfiguration, photoSettings: photoSettings, inProgressPhotoCaptureDelegates: inProgressPhotoCaptureDelegates)
    }()
    
    lazy var inProgressPhotoCaptureDelegates: [Int64 : PhotoCaptureProcessor] = {
       return [Int64 : PhotoCaptureProcessor]()
    }()
    
    func makeSceneDIContainer() -> SceneDIContainer {
        let dependencies = SceneDIContainer.Dependencies(authorizationManager: authorizationManager, cameraService: cameraService, inProgressPhotoCaptureDelegates: inProgressPhotoCaptureDelegates)
        return SceneDIContainer(dependencies: dependencies)
    }
    
}
