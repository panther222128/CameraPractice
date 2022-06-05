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
        let cameraDeviceConfiguration: CameraDeviceConfigurable & AudioDeviceConfigurable = DefaultDeviceConfiguration()
        let photoSettings: DefaultPhotoSettings = DefaultPhotoSettings()
        return DefaultCameraSerivce(deviceConfiguration: cameraDeviceConfiguration, photoSettings: photoSettings)
    }()
    
    func makeSceneDIContainer() -> SceneDIContainer {
        let dependencies = SceneDIContainer.Dependencies(authorizationManager: authorizationManager, cameraService: cameraService)
        return SceneDIContainer(dependencies: dependencies)
    }
    
}
