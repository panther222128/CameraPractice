//
//  MediaPickerViewModel.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/13.
//

import UIKit
import Photos

struct MediaPickerViewModelAction {
    let showPlaybackView: ((Int) -> Void)
}

protocol MediaPickerViewModel {
    var phAssetsRequestResult: Observable<PHFetchResult<PHAsset>?> { get }
    
    func fetchAssetCollection()
    func requestImage(at index: Int, size: CGSize, completion: @escaping ((UIImage?, [AnyHashable: Any]?) -> Void))
    func didSelectItem(at index: Int)
}

final class DefaultMediaPickerViewModel: MediaPickerViewModel {
    
    private let mediaPickerViewModelAction: MediaPickerViewModelAction
    private let phCachingImageManager = PHCachingImageManager()
    
    let phAssetsRequestResult: Observable<PHFetchResult<PHAsset>?>
    let options: PHImageRequestOptions
    
    init(mediaPickerViewModelAction: MediaPickerViewModelAction) {
        self.mediaPickerViewModelAction = mediaPickerViewModelAction
        self.phAssetsRequestResult = Observable(nil)
        self.options = PHImageRequestOptions()
    }
    
    func fetchAssetCollection() {
        self.options.isNetworkAccessAllowed = true
        self.phAssetsRequestResult.value = PHAsset.fetchAssets(with: nil)
    }
    
    func requestImage(at index: Int, size: CGSize, completion: @escaping ((UIImage?, [AnyHashable: Any]?) -> Void)) {
        guard let phAssetsRequestResult = self.phAssetsRequestResult.value else { return }
        let asset = phAssetsRequestResult.object(at: index)
        self.phCachingImageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: nil, resultHandler: completion)
    }
    
    func startCacheAssets(size: CGSize) {
        guard let phAssetsRequestResult = self.phAssetsRequestResult.value else { return }
        let count = phAssetsRequestResult.count
        let allAssets = phAssetsRequestResult.objects(at: IndexSet(integersIn: 0..<count))
        self.phCachingImageManager.startCachingImages(for: allAssets, targetSize: size, contentMode: .aspectFill, options: nil)
    }
    
    func didSelectItem(at index: Int) {
        self.mediaPickerViewModelAction.showPlaybackView(index)
    }

}
