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
        let inProgressPhotoCaptureDelegates: [Int64 : PhotoCaptureProcessor]
    }
    
    private let dependencies: Dependencies
//    lazy var locationSearchResultStorage: LocationSearchResultStorage = RealmLocationSearchResultStorage(maximumStorageLimit: 10)
    lazy var deviceConfiguration: DeviceConfigurable = {
        return DefaultDeviceConfiguration()
    }()
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    func makeViewFlowCoordinator(navigationController: UINavigationController) -> ViewFlowCoordinator {
        return ViewFlowCoordinator(navigationController: navigationController, dependencies: self)
    }
    
    // MARK: - Studio
    
    private func makeStudioRepository() -> StudioRepository {
        return DefaultStudioRepository()
    }
    
    private func makeStudioUseCase() -> StudioUseCase {
        return DefaultStudioUseCase(cameraRepository: self.makeStudioRepository(), authorizationManager: self.dependencies.authorizationManager, inProgressPhotoCaptureDelegates: self.dependencies.inProgressPhotoCaptureDelegates)
    }
    
    private func makeStudioViewModel() -> StudioViewModel {
        return DefaultStudioViewModel(studioUseCase: self.makeStudioUseCase())
    }
    
    private func makeRecordTimer() -> RecordTimerConfigurable {
        return RecordTimer()
    }
    
    private func makeStudio() -> StudioConfigurable {
        return DefaultStudio(deviceConfiguration: self.deviceConfiguration, photoSettings: DefaultPhotoSettings())
    }
    
    func makeStudioViewController() -> StudioViewController {
        return StudioViewController.create(with: self.makeStudioViewModel(), with: self.makeStudio(), with: self.makeRecordTimer())
    }

}
