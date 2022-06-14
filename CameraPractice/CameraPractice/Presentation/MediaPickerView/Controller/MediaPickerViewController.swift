//
//  MediaPickerViewController.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/13.
//

import UIKit
import Photos

class MediaPickerViewController: UIImagePickerController {

    private var viewModel: MediaPickerViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.allowsEditing = true
    }
    
    static func create(with viewModel: MediaPickerViewModel) -> MediaPickerViewController {
        let viewController = MediaPickerViewController()
        viewController.viewModel = viewModel
        return viewController
    }
    
}

extension MediaPickerViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        DispatchQueue.main.async {
            var targetImage: UIImage? = nil
            
            if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
                targetImage = image
            }
            
            guard let targetImage = targetImage else { return }

            self.viewModel.didSelectItem(of: targetImage)
        }
        
    }
    
}
