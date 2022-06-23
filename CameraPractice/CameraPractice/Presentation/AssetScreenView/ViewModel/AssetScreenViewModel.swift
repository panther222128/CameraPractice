//
//  PlaybackViewModel.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/13.
//

import UIKit
import Photos

struct AssetScreenViewModelAction {
    let popAssetScreenView: () -> Void
    let showTrimView: (Int) -> Void
}

protocol AssetScreenViewModel {
    var assetMediaType: Observable<PHAssetMediaType> { get }
    var assetsRequestResult: PHFetchResult<PHAsset>? { get }
    
    func fetchAssetCollection()
    func checkAssetMediaType()
    func requestImage(size: CGSize, completion: @escaping ((UIImage?, [AnyHashable: Any]?) -> Void))
    func requestVideo(completion: @escaping ((AVPlayerItem?, [AnyHashable: Any]?) -> Void))
    func didAddOverlay(of image: UIImage?, completion: @escaping (Result<URL?, Error>) -> Void)
    func didPressShowTrimViewButton()
    func didSaveMovie(url: URL?)
}

final class DefaultAssetScreenViewModel: AssetScreenViewModel {
    
    private let assetScreenUseCase: AssetScreenUseCase
    private let action: AssetScreenViewModelAction
    private let options: PHImageRequestOptions
    private let imageManager: PHImageManager
    private let assetIndex: Int
    
    let assetMediaType: Observable<PHAssetMediaType>
    var assetsRequestResult: PHFetchResult<PHAsset>?

    init(assetScreenUseCase: AssetScreenUseCase, assetIndex: Int, action: AssetScreenViewModelAction) {
        self.assetScreenUseCase = assetScreenUseCase
        self.assetIndex = assetIndex
        self.options = PHImageRequestOptions()
        self.imageManager = PHImageManager()
        self.assetMediaType = Observable(.unknown)
        self.assetsRequestResult = nil
        self.action = action
    }
    
    func fetchAssetCollection() {
        self.options.isNetworkAccessAllowed = true
        self.assetsRequestResult = PHAsset.fetchAssets(with: nil)
    }
    
    func checkAssetMediaType() {
        guard let assetsRequestResult = self.assetsRequestResult else { return }
        let asset = assetsRequestResult.object(at: self.assetIndex)
        self.assetMediaType.value = asset.mediaType
    }
    
    func requestImage(size: CGSize, completion: @escaping ((UIImage?, [AnyHashable: Any]?) -> Void)) {
        guard let assetsRequestResult = self.assetsRequestResult else { return }
        let asset = assetsRequestResult.object(at: self.assetIndex)
        self.imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: nil, resultHandler: completion)
    }
    
    func requestVideo(completion: @escaping ((AVPlayerItem?, [AnyHashable: Any]?) -> Void)) {
        guard let assetsRequestResult = self.assetsRequestResult else { return }
        let asset = assetsRequestResult.object(at: self.assetIndex)
        self.imageManager.requestPlayerItem(forVideo: asset, options: nil, resultHandler: completion)
    }
    
    func didAddOverlay(of image: UIImage?, completion: @escaping (Result<URL?, Error>) -> Void) {
        guard let assetsRequestResult = self.assetsRequestResult else { return }
        let asset = assetsRequestResult.object(at: self.assetIndex)
        self.imageManager.requestAVAsset(forVideo: asset, options: nil) { [weak self] asset, audioMix, error in
            guard let self = self else { return }
            if let asset = asset {
                guard let image = image else { return }
                self.assetScreenUseCase.addOverlay(of: image, to: asset) { result in
                    switch result {
                    case .success(let url):
                        completion(.success(url))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    func didSaveMovie(url: URL?) {
        guard let url = url else { return }
        self.assetScreenUseCase.saveRecordedMovie(url: url)
    }
    
    func didPressShowTrimViewButton() {
        self.action.showTrimView(self.assetIndex)
    }
    
}
