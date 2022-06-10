//
//  SceneDIContainer.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import UIKit

final class SceneDIContainer: ViewFlowCoordinatorDependencies {
    
    struct Dependencies {
    }
    
    private let dependencies: Dependencies
    
    lazy var deviceConfiguration: DeviceConfigurable = {
        return DefaultDeviceConfiguration()
    }()
    
    lazy var inProgressPhotoCaptureDelegates: [Int64 : PhotoCaptureProcessor] = {
       return [Int64 : PhotoCaptureProcessor]()
    }()
    
    lazy var authorizationManager: AuthorizationManager = {
        return DefaultAuthorizationManager()
    }()
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    func makeViewFlowCoordinator(navigationController: UINavigationController) -> ViewFlowCoordinator {
        return ViewFlowCoordinator(navigationController: navigationController, dependencies: self)
    }
    
    // MARK: - StudioView
    
    private func makeStudioRepository() -> StudioRepository {
        return DefaultStudioRepository()
    }
    
    private func makeStudioUseCase() -> StudioUseCase {
        return DefaultStudioUseCase(cameraRepository: self.makeStudioRepository(), authorizationManager: self.authorizationManager, inProgressPhotoCaptureDelegates: self.inProgressPhotoCaptureDelegates)
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
