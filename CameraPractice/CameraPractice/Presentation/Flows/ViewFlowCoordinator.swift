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
    func makeAssetScreenViewController(assetIndex: Int, action: AssetScreenViewModelAction) -> AssetScreenViewController
    func makeMovieTrimViewController(assetIndex: Int) -> MovieTrimViewController
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
        let action = MediaPickerViewModelAction(showAssetScreenView: self.showAssetScreenView)
        let viewController = dependencies.makeMediaPickerViewController(action: action)
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func showAssetScreenView(at assetIndex: Int) {
        let action = AssetScreenViewModelAction(popAssetScreenView: popViewController, showTrimView: self.showTrimView)
        let viewController = dependencies.makeAssetScreenViewController(assetIndex: assetIndex, action: action)
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func popViewController() {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func showTrimView(at assetIndex: Int) {
        let viewController = dependencies.makeMovieTrimViewController(assetIndex: assetIndex)
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
}
