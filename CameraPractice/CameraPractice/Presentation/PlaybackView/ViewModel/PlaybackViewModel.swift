//
//  PlaybackViewModel.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/13.
//

import UIKit

protocol PlaybackViewModel {
}

final class DefaultPlaybackViewModel: PlaybackViewModel {
    
    let assetIndex: Int
    
    init(assetIndex: Int) {
        self.assetIndex = assetIndex
    }
    
}
