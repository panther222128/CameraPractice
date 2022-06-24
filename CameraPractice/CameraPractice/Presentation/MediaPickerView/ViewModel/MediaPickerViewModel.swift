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
    
    func fetchAssetCollection()
    func requestImage(at index: Int, size: CGSize, resultHandler: @escaping ((UIImage?, [AnyHashable: Any]?) -> Void))
    func didSelectItem(at assetIndex: Int)
    func didCombineMovies(firstIndex: Int, secondIndex: Int, completion: @escaping (Result<URL?, Error>) -> Void)
}

final class DefaultMediaPickerViewModel: MediaPickerViewModel {
    
    private let mediaPickerUseCase: MediaPickerUseCase
    private let mediaPickerViewModelAction: MediaPickerViewModelAction
    
    let assetsRequestResult: Observable<PHFetchResult<PHAsset>?>
    
    init(mediaPickerUseCase: MediaPickerUseCase, mediaPickerViewModelAction: MediaPickerViewModelAction) {
        self.mediaPickerUseCase = mediaPickerUseCase
        self.mediaPickerViewModelAction = mediaPickerViewModelAction
        self.assetsRequestResult = Observable(nil)
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
    
    func didCombineMovies(firstIndex: Int, secondIndex: Int, completion: @escaping (Result<URL?, Error>) -> Void) {
        guard let assetsRequestResult = self.assetsRequestResult.value else { return }
        let firstAsset = assetsRequestResult.object(at: firstIndex)
        let secondAsset = assetsRequestResult.object(at: secondIndex)
        self.mediaPickerUseCase.combineMovies(firstAsset: firstAsset, secondAsset: secondAsset) { result in
            switch result {
            case .success(let url):
                completion(.success(url))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}
