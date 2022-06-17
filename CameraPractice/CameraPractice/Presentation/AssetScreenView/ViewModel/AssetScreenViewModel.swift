//
//  PlaybackViewModel.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/13.
//

import UIKit
import Photos

protocol AssetScreenViewModel {
    var phAssetMediaType: Observable<PHAssetMediaType> { get }
    var phAssetsRequestResult: Observable<PHFetchResult<PHAsset>?> { get }
    
    func fetchAssetCollection()
    func checkAssetMediaType()
    func requestImage(size: CGSize, completion: @escaping ((UIImage?, [AnyHashable: Any]?) -> Void))
    func requestVideo(completion: @escaping ((AVPlayerItem?, [AnyHashable: Any]?) -> Void))
    func didAddOverlay(completion: @escaping (AVAsset?) -> Void)
}

final class DefaultAssetScreenViewModel: AssetScreenViewModel {
    
    private let assetScreenUseCase: AssetScreenUseCase
    private let options: PHImageRequestOptions
    private let phImageManager: PHImageManager
    private let assetIndex: Int
    
    let phAssetMediaType: Observable<PHAssetMediaType>
    let phAssetsRequestResult: Observable<PHFetchResult<PHAsset>?>

    init(assetScreenUseCase: AssetScreenUseCase, assetIndex: Int) {
        self.assetScreenUseCase = assetScreenUseCase
        self.assetIndex = assetIndex
        self.options = PHImageRequestOptions()
        self.phImageManager = PHImageManager()
        self.phAssetMediaType = Observable(.unknown)
        self.phAssetsRequestResult = Observable(nil)
    }
    
    func fetchAssetCollection() {
        self.options.isNetworkAccessAllowed = true
        self.phAssetsRequestResult.value = PHAsset.fetchAssets(with: nil)
    }
    
    func checkAssetMediaType() {
        guard let phAssetsRequestResult = self.phAssetsRequestResult.value else { return }
        let asset = phAssetsRequestResult.object(at: self.assetIndex)
        self.phAssetMediaType.value = asset.mediaType
    }
    
    func requestImage(size: CGSize, completion: @escaping ((UIImage?, [AnyHashable: Any]?) -> Void)) {
        guard let phAssetsRequestResult = self.phAssetsRequestResult.value else { return }
        let asset = phAssetsRequestResult.object(at: self.assetIndex)
        self.phImageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: nil, resultHandler: completion)
    }
    
    func requestVideo(completion: @escaping ((AVPlayerItem?, [AnyHashable: Any]?) -> Void)) {
        guard let phAssetsRequestResult = self.phAssetsRequestResult.value else { return }
        let asset = phAssetsRequestResult.object(at: self.assetIndex)
        self.phImageManager.requestPlayerItem(forVideo: asset, options: nil, resultHandler: completion)
    }
    
    func didAddOverlay(completion: @escaping (AVAsset?) -> Void) {
        guard let phAssetsRequestResult = self.phAssetsRequestResult.value else { return }
        let asset = phAssetsRequestResult.object(at: self.assetIndex)
        self.phImageManager.requestAVAsset(forVideo: asset, options: nil) { asset, audioMix, error in
            if let asset = asset {
                completion(asset)
                self.assetScreenUseCase.addOverlay(to: asset) { url in
                    if let url = url {
                        self.didSaveMovie(outputUrl: url)
                    } else {
                        
                    }
                }
            }
        }
    }
    
    func didSaveMovie(outputUrl: URL?) {
        guard let outputUrl = outputUrl else { return }
        self.assetScreenUseCase.saveRecordedMovie(outputUrl: outputUrl)
    }
    
}
