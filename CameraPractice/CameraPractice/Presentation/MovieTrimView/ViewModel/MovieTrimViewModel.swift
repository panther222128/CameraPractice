//
//  MovieTrimViewModel.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/21.
//

import AVFoundation
import Photos
// Observable error needed

protocol MovieTrimViewModel {
    func fetchAssetCollection()
    func didTrimMovie(from startTime: Float, to endTime: Float, completion: @escaping (Result<URL?, MovieTrimEditorError>) -> Void)
}

final class DefaultMovieTrimViewModel: MovieTrimViewModel {
    
    private let movieTrimUseCase: MovieTrimUseCase
    private let assetIndex: Int
    let assetsRequestResult: Observable<PHFetchResult<PHAsset>?>
    
    init(movieTrimUseCase: MovieTrimUseCase, assetIndex: Int) {
        self.movieTrimUseCase = movieTrimUseCase
        self.assetIndex = assetIndex
        self.assetsRequestResult = Observable(nil)
    }
    
    func fetchAssetCollection() {
        self.assetsRequestResult.value = self.movieTrimUseCase.fetchAssets()
    }
    
    func didTrimMovie(from startTime: Float, to endTime: Float, completion: @escaping (Result<URL?, MovieTrimEditorError>) -> Void) {
        guard let assetsRequestResult = self.assetsRequestResult.value else { return }
        let asset = assetsRequestResult.object(at: self.assetIndex)
        self.movieTrimUseCase.trimMovie(of: asset, from: startTime, to: endTime, completion: completion)
    }

}
