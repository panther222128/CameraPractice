//
//  MovieTrimViewModel.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/21.
//

import AVFoundation
import Photos

protocol MovieTrimViewModel {
    func fetchAssetCollection()
    func didTrimMovie(from startTime: Float, to endTime: Float, completion: @escaping (Result<AVAsset, MovieTrimEditorError>) -> Void)
}

final class DefaultMovieTrimViewModel: MovieTrimViewModel {
    
    private let movieTrimUseCase: MovieTrimUseCase
    private let assetIndex: Int
    private let imageManager: PHImageManager
    private let options: PHImageRequestOptions
    let assetsRequestResult: Observable<PHFetchResult<PHAsset>?>
    
    init(movieTrimUseCase: MovieTrimUseCase, assetIndex: Int) {
        self.movieTrimUseCase = movieTrimUseCase
        self.assetIndex = assetIndex
        self.imageManager = PHImageManager()
        self.options = PHImageRequestOptions()
        self.assetsRequestResult = Observable(nil)
    }
    
    func fetchAssetCollection() {
        self.options.isNetworkAccessAllowed = true
        self.assetsRequestResult.value = PHAsset.fetchAssets(with: nil)
    }
    
    func didTrimMovie(from startTime: Float, to endTime: Float, completion: @escaping (Result<AVAsset, MovieTrimEditorError>) -> Void) {
        guard let assetsRequestResult = self.assetsRequestResult.value else { return }
        let asset = assetsRequestResult.object(at: self.assetIndex)
        self.imageManager.requestAVAsset(forVideo: asset, options: nil) { [weak self] asset, audioMix, error in
            guard let self = self else { return }
            if let asset = asset {
                self.movieTrimUseCase.trimMovie(of: asset, from: startTime, to: endTime) { result in
                    switch result {
                    case .success(let url):
                        self.movieTrimUseCase.saveRecordedMovie(outputUrl: url)
                        completion(.success(asset))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                completion(.success(asset))
            }
        }
    }
    
}
