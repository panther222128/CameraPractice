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
    
    private func makeStudioViewModel(action: StudioViewModelAction) -> StudioViewModel {
        return DefaultStudioViewModel(studioUseCase: self.makeStudioUseCase(), action: action)
    }
    
    private func makeRecordTimer() -> RecordTimerConfigurable {
        return RecordTimer()
    }
    
    private func makeStudio() -> StudioConfigurable {
        return DefaultStudio(deviceConfiguration: self.deviceConfiguration, photoSettings: DefaultPhotoSettings())
    }
    
    func makeStudioViewController(action: StudioViewModelAction) -> StudioViewController {
        return StudioViewController.create(with: self.makeStudioViewModel(action: action), with: self.makeStudio(), with: self.makeRecordTimer())
    }

    // MARK: - MediaPicker
    
    private func makeMediaPickerRepository() -> MediaPickerRepository {
        return DefaultMediaPickerRepository()
    }
    
    private func makeMediaPickerUseCase() -> MediaPickerUseCase {
        return DefaultMediaPickerUseCase()
    }
    
    private func makeMediaPickerViewModel(mediaPickerViewModelAction: MediaPickerViewModelAction) -> MediaPickerViewModel {
        return DefaultMediaPickerViewModel(mediaPickerViewModelAction: mediaPickerViewModelAction)
    }

    func makeMediaPickerViewController(action: MediaPickerViewModelAction) -> MediaPickerViewController {
        return MediaPickerViewController.create(with: self.makeMediaPickerViewModel(mediaPickerViewModelAction: action))
    }
    
    // MARK: - Playback
    
    private func makePlaybackRepository() -> PlaybackRepository {
        return DefaultPlaybackRepository()
    }
    
    private func makePlaybackUseCase() -> PlaybackUseCase {
        return DefaultPlaybackUseCase()
    }
    
    private func makePlaybackViewModel() -> PlaybackViewModel {
        return DefaultPlaybackViewModel()
    }
    
    func makePlaybackViewController() -> PlaybackViewController {
        return PlaybackViewController.create(with: self.makePlaybackViewModel())
    }
    
}
