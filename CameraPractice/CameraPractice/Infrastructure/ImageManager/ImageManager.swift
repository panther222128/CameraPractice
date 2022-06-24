//
//  ImageManager.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/24.
//

import Photos
import UIKit

protocol ImageManager {
    func requestAVAssetVideoWithDefaultOptions(for asset: PHAsset, resultHandler: @escaping (AVAsset?, AVAudioMix?, [AnyHashable : Any]?) -> Void)
    func requestImage(of asset: PHAsset, size: CGSize, resultHandler: @escaping (UIImage?, [AnyHashable : Any]?) -> Void)
    func requestPlayerItem(of asset: PHAsset, resultHandler: @escaping (AVPlayerItem?, [AnyHashable : Any]?) -> Void)
}

final class DefaultImageManager: PHImageManager, ImageManager {
    
    private let defaultImageRequestOptions: PHImageRequestOptions & ImageRequestOptions
    private let defaultVideoRequestOptions: PHVideoRequestOptions & VideoRequestOptions
    
    override init() {
        self.defaultImageRequestOptions = DefaultImageRequestOptions()
        self.defaultVideoRequestOptions = DefaultVideoRequestOptions()
    }
    
    func requestImage(of asset: PHAsset, size: CGSize, resultHandler: @escaping (UIImage?, [AnyHashable : Any]?) -> Void) {
        self.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: self.defaultImageRequestOptions, resultHandler: resultHandler)
    }
    
    func requestPlayerItem(of asset: PHAsset, resultHandler: @escaping (AVPlayerItem?, [AnyHashable : Any]?) -> Void) {
        self.requestPlayerItem(forVideo: asset, options: self.defaultVideoRequestOptions, resultHandler: resultHandler)
    }
    
    // MARK: - This method has to return PHImageRequestID if you want to cancel during request.
    
    func requestAVAssetVideoWithDefaultOptions(for asset: PHAsset, resultHandler: @escaping (AVAsset?, AVAudioMix?, [AnyHashable : Any]?) -> Void) {
        self.requestAVAsset(forVideo: asset, options: defaultVideoRequestOptions, resultHandler: resultHandler)
    }
    
}
