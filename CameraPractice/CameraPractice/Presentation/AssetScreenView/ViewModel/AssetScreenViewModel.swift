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
    var assetsRequestResult: Observable<PHFetchResult<PHAsset>?> { get }
    
    func fetchAssetCollection()
    func checkAssetMediaType()
    func requestImage(size: CGSize, completion: @escaping ((UIImage?, [AnyHashable: Any]?) -> Void))
    func requestVideo(completion: @escaping ((AVPlayerItem?, [AnyHashable: Any]?) -> Void))
    func didAddOverlay(of image: UIImage?, completion: @escaping (Result<AVAsset?, Error>) -> Void)
    func didPressShowTrimViewButton()
}

final class DefaultAssetScreenViewModel: AssetScreenViewModel {
    
    private let assetScreenUseCase: AssetScreenUseCase
    private let action: AssetScreenViewModelAction
    private let options: PHImageRequestOptions
    private let phImageManager: PHImageManager
    private let assetIndex: Int
    
    let assetMediaType: Observable<PHAssetMediaType>
    let assetsRequestResult: Observable<PHFetchResult<PHAsset>?>

    init(assetScreenUseCase: AssetScreenUseCase, assetIndex: Int, action: AssetScreenViewModelAction) {
        self.assetScreenUseCase = assetScreenUseCase
        self.assetIndex = assetIndex
        self.options = PHImageRequestOptions()
        self.phImageManager = PHImageManager()
        self.assetMediaType = Observable(.unknown)
        self.assetsRequestResult = Observable(nil)
        self.action = action
    }
    
    func fetchAssetCollection() {
        self.options.isNetworkAccessAllowed = true
        self.assetsRequestResult.value = PHAsset.fetchAssets(with: nil)
    }
    
    func checkAssetMediaType() {
        guard let phAssetsRequestResult = self.assetsRequestResult.value else { return }
        let asset = phAssetsRequestResult.object(at: self.assetIndex)
        self.assetMediaType.value = asset.mediaType
    }
    
    func requestImage(size: CGSize, completion: @escaping ((UIImage?, [AnyHashable: Any]?) -> Void)) {
        guard let phAssetsRequestResult = self.assetsRequestResult.value else { return }
        let asset = phAssetsRequestResult.object(at: self.assetIndex)
        self.phImageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: nil, resultHandler: completion)
    }
    
    func requestVideo(completion: @escaping ((AVPlayerItem?, [AnyHashable: Any]?) -> Void)) {
        guard let phAssetsRequestResult = self.assetsRequestResult.value else { return }
        let asset = phAssetsRequestResult.object(at: self.assetIndex)
        self.phImageManager.requestPlayerItem(forVideo: asset, options: nil, resultHandler: completion)
    }
    
    func didAddOverlay(of image: UIImage?, completion: @escaping (Result<AVAsset?, Error>) -> Void) {
        guard let phAssetsRequestResult = self.assetsRequestResult.value else { return }
        let asset = phAssetsRequestResult.object(at: self.assetIndex)
        self.phImageManager.requestAVAsset(forVideo: asset, options: nil) { [weak self] asset, audioMix, error in
            guard let self = self else { return }
            if let asset = asset {
                guard let image = image else { return }
                self.assetScreenUseCase.addOverlay(of: image, to: asset) { result in
                    switch result {
                    case .success(let url):
                        self.assetScreenUseCase.saveRecordedMovie(outputUrl: url)
                        completion(.success(asset))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                completion(.success(asset))
            }
        }
        self.action.popAssetScreenView()
    }
    
    func didSaveMovie(outputUrl: URL?) {
        guard let outputUrl = outputUrl else { return }
        self.assetScreenUseCase.saveRecordedMovie(outputUrl: outputUrl)
    }
    
    func didPressShowTrimViewButton() {
        self.action.showTrimView(self.assetIndex)
    }
    
}
