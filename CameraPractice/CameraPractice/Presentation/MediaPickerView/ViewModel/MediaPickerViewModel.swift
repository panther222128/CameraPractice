//
//  MediaPickerViewModel.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/13.
//

import UIKit

struct MediaPickerViewModelAction {
    let showPlaybackView: ((UIImage) -> Void)
}

protocol MediaPickerViewModel {
    func didSelectItem(of image: UIImage)
}

final class DefaultMediaPickerViewModel: MediaPickerViewModel {
    
    private let mediaPickerViewModelAction: MediaPickerViewModelAction

    init(mediaPickerViewModelAction: MediaPickerViewModelAction) {
        self.mediaPickerViewModelAction = mediaPickerViewModelAction
    }
    
    func didSelectItem(of image: UIImage) {
        self.mediaPickerViewModelAction.showPlaybackView(image)
    }
    
}
