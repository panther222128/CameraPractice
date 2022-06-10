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
    
    lazy var deviceConfiguration: DeviceConfigurable = {
        return DefaultDeviceConfiguration()
    }()
    
    lazy var studioConfiguration: StudioConfigurable = {
        let cameraDeviceConfiguration: DeviceConfigurable = DefaultDeviceConfiguration()
        let photoSettings: AVCapturePhotoSettings = AVCapturePhotoSettings()
        return DefaultStudio(deviceConfiguration: cameraDeviceConfiguration, photoSettings: photoSettings)
    }()
    
    lazy var inProgressPhotoCaptureDelegates: [Int64 : PhotoCaptureProcessor] = {
       return [Int64 : PhotoCaptureProcessor]()
    }()
    
    func makeSceneDIContainer() -> SceneDIContainer {
        let dependencies = SceneDIContainer.Dependencies(deviceConfiguration: deviceConfiguration, authorizationManager: authorizationManager, inProgressPhotoCaptureDelegates: inProgressPhotoCaptureDelegates)
        return SceneDIContainer(dependencies: dependencies)
    }
    
}
