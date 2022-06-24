//
//  PlaybackViewModel.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/13.
//

import UIKit
import Photos

// Observable error needed

struct AssetScreenViewModelAction {
    let popAssetScreenView: () -> Void
    let showTrimView: (Int) -> Void
}

protocol AssetScreenViewModel {
    var assetMediaType: Observable<PHAssetMediaType> { get }
    var assetsRequestResult: PHFetchResult<PHAsset>? { get }
    
    func fetchAssetCollection()
    func checkAssetMediaType()
    func requestImage(size: CGSize, resultHandler: @escaping ((UIImage?, [AnyHashable: Any]?) -> Void))
    func requestVideo(resultHandler: @escaping ((AVPlayerItem?, [AnyHashable: Any]?) -> Void))
    func didAddOverlay(of image: UIImage?, completion: @escaping (Result<URL?, Error>) -> Void)
    func didPressShowTrimViewButton()
    func didApplyLetterBox(completion: @escaping (Result<URL?, Error>) -> Void)
}

final class DefaultAssetScreenViewModel: AssetScreenViewModel {
    
    private let assetScreenUseCase: AssetScreenUseCase
    private let action: AssetScreenViewModelAction
    private let assetIndex: Int
    
    let assetMediaType: Observable<PHAssetMediaType>
    var assetsRequestResult: PHFetchResult<PHAsset>?

    init(assetScreenUseCase: AssetScreenUseCase, assetIndex: Int, action: AssetScreenViewModelAction) {
        self.assetScreenUseCase = assetScreenUseCase
        self.assetIndex = assetIndex
        self.assetMediaType = Observable(.unknown)
        self.assetsRequestResult = nil
        self.action = action
    }
    
    func fetchAssetCollection() {
        self.assetsRequestResult = self.assetScreenUseCase.fetchAssets()
    }
    
    func checkAssetMediaType() {
        guard let assetsRequestResult = self.assetsRequestResult else { return }
        let asset = assetsRequestResult.object(at: self.assetIndex)
        self.assetMediaType.value = asset.mediaType
    }
    
    func requestImage(size: CGSize, resultHandler: @escaping ((UIImage?, [AnyHashable: Any]?) -> Void)) {
        guard let assetsRequestResult = self.assetsRequestResult else { return }
        let asset = assetsRequestResult.object(at: self.assetIndex)
        self.assetScreenUseCase.requestImage(of: asset, size: size, resultHandler: resultHandler)
    }
    
    func requestVideo(resultHandler: @escaping ((AVPlayerItem?, [AnyHashable: Any]?) -> Void)) {
        guard let assetsRequestResult = self.assetsRequestResult else { return }
        let asset = assetsRequestResult.object(at: self.assetIndex)
        self.assetScreenUseCase.requestPlayerItem(of: asset, resultHandler: resultHandler)
    }
    
    func didAddOverlay(of image: UIImage?, completion: @escaping (Result<URL?, Error>) -> Void) {
        guard let assetsRequestResult = self.assetsRequestResult else { return }
        let asset = assetsRequestResult.object(at: self.assetIndex)
        self.assetScreenUseCase.addOverlay(of: image, to: asset) { result in
            switch result {
            case .success(let url):
                completion(.success(url))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func didPressShowTrimViewButton() {
        self.action.showTrimView(self.assetIndex)
    }
    
    func didApplyLetterBox(completion: @escaping (Result<URL?, Error>) -> Void) {
        guard let assetsRequestResult = self.assetsRequestResult else { return }
        let asset = assetsRequestResult.object(at: self.assetIndex)
        self.assetScreenUseCase.applyLetterbox(to: asset) { result in
            switch result {
            case .success(let url):
                completion(.success(url))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}
