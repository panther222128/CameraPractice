//
//  DefaultPlaybackRepository.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/14.
//

import UIKit
import Photos

final class DefaultAssetScreenRepository: AssetScreenRepository {
    
    private let imageManager: ImageManager
    
    init(imageManager: ImageManager) {
        self.imageManager = imageManager
    }
    
    func requestImage(of asset: PHAsset, size: CGSize, resultHandler: @escaping (UIImage?, [AnyHashable : Any]?) -> Void) {
        self.imageManager.requestImage(of: asset, size: size, resultHandler: resultHandler)
    }
    
    func requestPlayerItem(of asset: PHAsset, resultHandler: @escaping (AVPlayerItem?, [AnyHashable : Any]?) -> Void) {
        self.imageManager.requestPlayerItem(of: asset, resultHandler: resultHandler)
    }
    
    func requestAVAssetVideoWithDefaultOptions(of asset: PHAsset, resultHandler: @escaping (AVAsset?, AVAudioMix?, [AnyHashable : Any]?) -> Void) {
        self.imageManager.requestAVAssetVideoWithDefaultOptions(for: asset, resultHandler: resultHandler)
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
