//
//  SceneDIContainer.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import UIKit

final class SceneDIContainer: ViewFlowCoordinatorDependencies {
    
    struct Dependencies {
//        let apiDataTransferService: DataTransferService
        let authorizationManager: AuthorizationManager
        let cameraService: CameraService
        let inProgressPhotoCaptureDelegates: [Int64 : PhotoCaptureProcessor]
    }
    
    private let dependencies: Dependencies
//    lazy var locationSearchResultStorage: LocationSearchResultStorage = RealmLocationSearchResultStorage(maximumStorageLimit: 10)
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    func makeViewFlowCoordinator(navigationController: UINavigationController) -> ViewFlowCoordinator {
        return ViewFlowCoordinator(navigationController: navigationController, dependencies: self)
    }
    
    // MARK: - Camera
    
    private func makeCameraRepository() -> CameraRepository {
        return DefaultCameraRepository()
    }
    
    private func makeCameraSearchUseCase() -> CameraUseCase {
        return DefaultCameraUseCase(cameraRepository: self.makeCameraRepository(), authorizationManager: self.dependencies.authorizationManager, inProgressPhotoCaptureDelegates: self.dependencies.inProgressPhotoCaptureDelegates)
    }
    
    private func makeCameraViewModel() -> CameraViewModel {
        return DefaultCameraViewModel(cameraUseCase: self.makeCameraSearchUseCase())
    }
    
    func makeCameraViewController() -> CameraViewController {
        return CameraViewController.create(with: self.makeCameraViewModel(), with: self.dependencies.cameraService)
    }

}
