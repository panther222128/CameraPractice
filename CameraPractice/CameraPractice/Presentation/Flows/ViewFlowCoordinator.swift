//
//  ViewFlowCoordinator.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import UIKit

protocol ViewFlowCoordinatorDependencies {
    func makeCameraViewController() -> CameraViewController
}

final class ViewFlowCoordinator {
    
    private weak var navigationController: UINavigationController?
    private let dependencies: ViewFlowCoordinatorDependencies
    
    private weak var cameraViewController: CameraViewController?
    
    init(navigationController: UINavigationController, dependencies: ViewFlowCoordinatorDependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }
    
    func start() {
        let viewController = dependencies.makeCameraViewController()
        
        self.navigationController?.pushViewController(viewController, animated: true)
        self.cameraViewController = viewController
    }
    
}
