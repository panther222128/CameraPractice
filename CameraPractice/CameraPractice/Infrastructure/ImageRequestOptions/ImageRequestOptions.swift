//
//  ImageRequestOptions.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/24.
//

import Photos

protocol ImageRequestOptions {
    
}

final class DefaultImageRequestOptions: PHImageRequestOptions, ImageRequestOptions {
    
    override init() {
        super.init()
        self.isNetworkAccessAllowed = true
    }
    
}
