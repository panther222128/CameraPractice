//
//  PlaybackViewModel.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/13.
//

import UIKit

protocol PlaybackViewModel {
    var image: Observable<UIImage?> { get }
}

final class DefaultPlaybackViewModel: PlaybackViewModel {
    
    let image: Observable<UIImage?>
    
    init() {
        self.image = Observable(nil)
    }
    
}
