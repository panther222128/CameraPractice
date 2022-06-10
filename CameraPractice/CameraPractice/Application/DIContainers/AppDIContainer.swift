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

    func makeSceneDIContainer() -> SceneDIContainer {
        let dependencies = SceneDIContainer.Dependencies()
        return SceneDIContainer(dependencies: dependencies)
    }
    
}
