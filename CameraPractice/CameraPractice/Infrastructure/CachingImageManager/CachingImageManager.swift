//
//  CachingImageManager.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/24.
//

import Photos
import UIKit

protocol CachingImageManager {
    func requestAVAssetVideoWithDefaultOptions(for asset: PHAsset, resultHandler: @escaping (AVAsset?, AVAudioMix?, [AnyHashable : Any]?) -> Void) -> PHImageRequestID
    func requestImage(of asset: PHAsset, size: CGSize, resultHandler: @escaping ((UIImage?, [AnyHashable: Any]?) -> Void))
}

final class DefaultCachingImageManager: PHCachingImageManager, CachingImageManager {
    
    private let defaultVideoRequestOptions: PHVideoRequestOptions & VideoRequestOptions
    
    override init() {
        self.defaultVideoRequestOptions = DefaultVideoRequestOptions()
    }
    
    func requestAVAssetVideoWithDefaultOptions(for asset: PHAsset, resultHandler: @escaping (AVAsset?, AVAudioMix?, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        self.requestAVAsset(forVideo: asset, options: defaultVideoRequestOptions, resultHandler: resultHandler)
    }
    
    func requestImage(of asset: PHAsset, size: CGSize, resultHandler: @escaping ((UIImage?, [AnyHashable: Any]?) -> Void)) {
        self.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: nil, resultHandler: resultHandler)
    }
    
}
