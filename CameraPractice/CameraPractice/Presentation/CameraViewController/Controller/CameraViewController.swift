//
//  CameraViewController.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import UIKit
import AVFoundation

final class CameraViewController: UIViewController {

    private var viewModel: CameraViewModel!
    
    // MARK: - Related with session
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    private var previewView: PreviewView!
    
    // MARK: - viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    static func create(with viewModel: CameraViewModel) -> CameraViewController {
        let viewController = CameraViewController()
        viewController.viewModel = viewModel
        return viewController
    }
    
//    private func checkAuthorization() {
//        switch AVCaptureDevice.authorizationStatus(for: .video) {
//        case .authorized:
//            break
//        case .notDetermined:
//            sessionQueue.suspend()
//            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
//                if !granted {
//                    self.sessionSetupResult = .notAuthorized
//                }
//                self.sessionQueue.resume()
//            })
//        default:
//            sessionSetupResult = .notAuthorized
//        }
//    }
    
}
