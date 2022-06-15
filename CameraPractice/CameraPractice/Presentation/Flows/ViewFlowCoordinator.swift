//
//  ViewFlowCoordinator.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import UIKit

protocol ViewFlowCoordinatorDependencies {
    func makeStudioViewController(action: StudioViewModelAction) -> StudioViewController
    func makeMediaPickerViewController(action: MediaPickerViewModelAction) -> MediaPickerViewController
    func makePlaybackViewController() -> PlaybackViewController
}

final class ViewFlowCoordinator {
    
    private weak var navigationController: UINavigationController?
    private let dependencies: ViewFlowCoordinatorDependencies
    
    private weak var cameraViewController: StudioViewController?
    
    init(navigationController: UINavigationController, dependencies: ViewFlowCoordinatorDependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }
    
    func start() {
        let action = StudioViewModelAction(presentMediaPickerView: self.showMediaPickerView)
        let viewController = dependencies.makeStudioViewController(action: action)
        
        self.navigationController?.pushViewController(viewController, animated: true)
        self.cameraViewController = viewController
    }
    
    private func showMediaPickerView() {
        let action = MediaPickerViewModelAction(showPlaybackView: self.showPlaybackView)
        let viewController = dependencies.makeMediaPickerViewController(action: action)
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func showPlaybackView(at index: Int) {
        let viewController = dependencies.makePlaybackViewController()
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
}
