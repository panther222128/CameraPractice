//
//  VideoRequestOptions.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/24.
//

import Photos

protocol VideoRequestOptions {
    
}

final class DefaultVideoRequestOptions: PHVideoRequestOptions, VideoRequestOptions {
    
    override init() {
        super.init()
        self.isNetworkAccessAllowed = true
    }
    
}
