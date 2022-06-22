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
    func didCombineMovies(firstIndex: Int, secondIndex: Int, completion: @escaping (Result<URL?, Error>) -> Void)
}

final class DefaultMediaPickerViewModel: MediaPickerViewModel {
    
    private let mediaPickerUseCase: MediaPickerUseCase
    private let mediaPickerViewModelAction: MediaPickerViewModelAction
    private let cachingImageManager: PHCachingImageManager
    private let imageManager: PHImageManager
    private let options: PHImageRequestOptions
    
    let assetsRequestResult: Observable<PHFetchResult<PHAsset>?>
    
    init(mediaPickerUseCase: MediaPickerUseCase, mediaPickerViewModelAction: MediaPickerViewModelAction) {
        self.mediaPickerUseCase = mediaPickerUseCase
        self.mediaPickerViewModelAction = mediaPickerViewModelAction
        self.assetsRequestResult = Observable(nil)
        self.cachingImageManager = PHCachingImageManager()
        self.imageManager = PHImageManager()
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
    
    func didCombineMovies(firstIndex: Int, secondIndex: Int, completion: @escaping (Result<URL?, Error>) -> Void) {
        guard let assetsRequestResult = self.assetsRequestResult.value else { return }
        let firstAsset = assetsRequestResult.object(at: firstIndex)
        let secondAsset = assetsRequestResult.object(at: secondIndex)
        self.imageManager.requestAVAsset(forVideo: firstAsset, options: nil) { [weak self] first, audioMix, error in
            guard let self = self else { return }
            if let first = first {
                self.imageManager.requestAVAsset(forVideo: secondAsset, options: nil) { [weak self] second, audioMix, error in
                    guard let self = self else { return }
                    if let second = second {
                        self.mediaPickerUseCase.combineMovies(first: first, second: second) { result in
                            print(first)
                            switch result {
                            case .success(let url):
                                self.mediaPickerUseCase.saveRecordedMovie(outputUrl: url)
                                completion(.success(url))
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    }
                }
            }
        }
    }
    
}
