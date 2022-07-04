//
//  MediaPickerViewModel.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/13.
//

import Photos
import UIKit

// Observable error needed

struct MediaPickerViewModelAction {
    let showAssetScreenView: ((Int) -> Void)
}

protocol MediaPickerViewModel {
    var assetsRequestResult: Observable<PHFetchResult<PHAsset>?> { get }
    var isError: Observable<Bool?> { get }
    var error: Observable<Error?> { get }
    
    func fetchAssetCollection()
    func requestImage(at index: Int, size: CGSize, resultHandler: @escaping ((UIImage?, [AnyHashable: Any]?) -> Void))
    func didSelectItem(at assetIndex: Int)
    func didCombineMovies(assetIndex: [Int], completion: @escaping (Result<URL?, Error>) -> Void)
}

final class DefaultMediaPickerViewModel: MediaPickerViewModel {
    
    private let mediaPickerUseCase: MediaPickerUseCase
    private let mediaPickerViewModelAction: MediaPickerViewModelAction
    
    let assetsRequestResult: Observable<PHFetchResult<PHAsset>?>
    let isError: Observable<Bool?>
    let error: Observable<Error?>
    
    init(mediaPickerUseCase: MediaPickerUseCase, mediaPickerViewModelAction: MediaPickerViewModelAction) {
        self.mediaPickerUseCase = mediaPickerUseCase
        self.mediaPickerViewModelAction = mediaPickerViewModelAction
        self.assetsRequestResult = Observable(nil)
        self.isError = Observable(nil)
        self.error = Observable(nil)
    }
    
    func fetchAssetCollection() {
        self.assetsRequestResult.value = self.mediaPickerUseCase.fetchAssets()
    }
    
    func requestImage(at index: Int, size: CGSize, resultHandler: @escaping ((UIImage?, [AnyHashable: Any]?) -> Void)) {
        guard let assetsRequestResult = self.assetsRequestResult.value else { return }
        let asset = assetsRequestResult.object(at: index)
        self.mediaPickerUseCase.fetchCachingImage(of: asset, size: size, resultHandler: resultHandler)
    }

    func didSelectItem(at assetIndex: Int) {
        self.mediaPickerViewModelAction.showAssetScreenView(assetIndex)
    }
    
    func didCombineMovies(assetIndex: [Int], completion: @escaping (Result<URL?, Error>) -> Void) {
        guard let assetsRequestResult = self.assetsRequestResult.value else { return }
        let firstAsset = assetsRequestResult.object(at: assetIndex[0])
        let secondAsset = assetsRequestResult.object(at: assetIndex[1])
        var assets = [PHAsset]()
        assets.append(firstAsset)
        assets.append(secondAsset)
        self.mediaPickerUseCase.combineMovies(assets: assets) { result in
            switch result {
            case .success(let url):
                completion(.success(url))
            case .failure(let error):
                print(error)
                completion(.failure(error))
            }
        }
    }
    
}
