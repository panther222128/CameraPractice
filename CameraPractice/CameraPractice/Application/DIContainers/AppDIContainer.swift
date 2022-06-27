//
//  AppDIContainer.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import AVFoundation

final class AppDIContainer {
    
    lazy var imageManager: ImageManager = {
        let imageManager = DefaultImageManager()
        return imageManager
    }()
    
    lazy var cachingImageManager: CachingImageManager = {
        let cachingImageManager = DefaultCachingImageManager()
        return cachingImageManager
    }()

    func makeSceneDIContainer() -> SceneDIContainer {
        let dependencies = SceneDIContainer.Dependencies(imageManager: imageManager, cachingImageManager: cachingImageManager)
        return SceneDIContainer(dependencies: dependencies)
    }
    
}
