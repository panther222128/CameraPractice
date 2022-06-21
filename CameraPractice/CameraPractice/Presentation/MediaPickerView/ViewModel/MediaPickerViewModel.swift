//
//  MediaPickerViewModel.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/13.
//

import UIKit
import Photos

struct MediaPickerViewModelAction {
    let showAssetScreenView: ((Int) -> Void)
}

protocol MediaPickerViewModel {
    var assetsRequestResult: Observable<PHFetchResult<PHAsset>?> { get }
    
    func fetchAssetCollection()
    func requestImage(at index: Int, size: CGSize, completion: @escaping ((UIImage?, [AnyHashable: Any]?) -> Void))
    func didSelectItem(at assetIndex: Int)
}

final class DefaultMediaPickerViewModel: MediaPickerViewModel {
    
    private let mediaPickerViewModelAction: MediaPickerViewModelAction
    private let cachingImageManager: PHCachingImageManager
    private let options: PHImageRequestOptions
    
    let assetsRequestResult: Observable<PHFetchResult<PHAsset>?>
    
    init(mediaPickerViewModelAction: MediaPickerViewModelAction) {
        self.mediaPickerViewModelAction = mediaPickerViewModelAction
        self.assetsRequestResult = Observable(nil)
        self.cachingImageManager = PHCachingImageManager()
        self.options = PHImageRequestOptions()
    }
    
    func fetchAssetCollection() {
        self.options.isNetworkAccessAllowed = true
        self.assetsRequestResult.value = PHAsset.fetchAssets(with: nil)
    }
    
    func requestImage(at index: Int, size: CGSize, completion: @escaping ((UIImage?, [AnyHashable: Any]?) -> Void)) {
        guard let assetsRequestResult = self.assetsRequestResult.value else { return }
        let asset = assetsRequestResult.object(at: index)
        self.cachingImageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: nil, resultHandler: completion)
    }

    func didSelectItem(at assetIndex: Int) {
        self.mediaPickerViewModelAction.showAssetScreenView(assetIndex)
    }

}
