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
    
    // MARK: - AssetScreen
    
    private func makeAssetScreenRepository() -> PlaybackRepository {
        return DefaultPlaybackRepository()
    }
    
    private func makeAssetEditor() -> AssetEditor {
        return DefaultAssetEditor()
    }
    
    private func makeAssetScreenUseCase() -> AssetScreenUseCase {
        return DefaultAssetScreenUseCase(assetEditor: self.makeAssetEditor())
    }
    
    private func makeAssetScreenViewModel(assetIndex: Int, action: AssetScreenViewModelAction) -> AssetScreenViewModel {
        return DefaultAssetScreenViewModel(assetScreenUseCase: self.makeAssetScreenUseCase(), assetIndex: assetIndex, action: action)
    }
    
    func makeAssetScreenViewController(assetIndex: Int, action: AssetScreenViewModelAction) -> AssetScreenViewController {
        return AssetScreenViewController.create(with: self.makeAssetScreenViewModel(assetIndex: assetIndex, action: action))
    }
    
    // MARK: - MovieTrim
    
    private func makeMovieTrimRepository() -> MovieTrimRepository {
        return DefaultMovieTrimRepository()
    }
    
    private func makeMovieTrimEditor() -> MovieTrimEditor {
        return DefaultMovieTrimEditor()
    }
    
    private func makeMovieTrimUseCase() -> MovieTrimUseCase {
        return DefaultMovieTrimUseCase(movieTrimEditor: self.makeMovieTrimEditor())
    }
    
    private func makeMovieTrimViewModel(assetIndex: Int) -> MovieTrimViewModel {
        return DefaultMovieTrimViewModel(movieTrimUseCase: self.makeMovieTrimUseCase(), assetIndex: assetIndex)
    }
    
    func makeMovieTrimViewController(assetIndex: Int) -> MovieTrimViewController {
        return MovieTrimViewController.create(with: self.makeMovieTrimViewModel(assetIndex: assetIndex))
    }
    
}
