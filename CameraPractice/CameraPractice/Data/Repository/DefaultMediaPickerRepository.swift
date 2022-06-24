//
//  DefaultMediaPickerRepository.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/13.
//

import Photos
import UIKit

final class DefaultMediaPickerRepository: MediaPickerRepository {
    
    private let imageManager: ImageManager
    private let cachingImageManager: CachingImageManager
    
    init(imageManager: ImageManager, cachingImageManager: CachingImageManager) {
        self.imageManager = imageManager
        self.cachingImageManager = cachingImageManager
    }
    
    func requestAVAssetVideoWithDefaultOptions(of asset: PHAsset, resultHandler: @escaping (AVAsset?, AVAudioMix?, [AnyHashable : Any]?) -> Void) {
        self.imageManager.requestAVAssetVideoWithDefaultOptions(for: asset, resultHandler: resultHandler)
    }
    
    func requestCachingImage(of asset: PHAsset, size: CGSize, resultHandler: @escaping ((UIImage?, [AnyHashable : Any]?) -> Void)) {
        self.cachingImageManager.requestImage(of: asset, size: size, resultHandler: resultHandler)
    }
    
    func fetchAssets() -> PHFetchResult<PHAsset> {
        return PHAsset.fetchAssets(with: nil)
    }
    
    func saveAsset(outputUrl: URL?) {
        guard let outputUrl = outputUrl else { return }
        let recordedMovieUrl = outputUrl as URL
        UISaveVideoAtPathToSavedPhotosAlbum(recordedMovieUrl.path, nil, nil, nil)
    }
    
}
