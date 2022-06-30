//
//  MediaPickerUseCase.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/13.
//

import AVFoundation
import UIKit
import Photos

protocol MediaPickerUseCase {
    func combineMovies(firstAsset: PHAsset, secondAsset: PHAsset, completion: @escaping (Result<URL?, Error>) -> Void)
    func fetchAssets() -> PHFetchResult<PHAsset>
    func fetchCachingImage(of asset: PHAsset, size: CGSize, resultHandler: @escaping ((UIImage?, [AnyHashable : Any]?) -> Void))
}

final class DefaultMediaPickerUseCase: MediaPickerUseCase {

    private let mediaPickerRepository: MediaPickerRepository
    private let movieCombineEditor: MovieCombineEditor
    
    init(mediaPickerRepository: MediaPickerRepository, movieCombineEditor: MovieCombineEditor) {
        self.mediaPickerRepository = mediaPickerRepository
        self.movieCombineEditor = movieCombineEditor
    }
    
    // MARK: - Need to error handling
    
    func combineMovies(firstAsset: PHAsset, secondAsset: PHAsset, completion: @escaping (Result<URL?, Error>) -> Void) {
        self.requestAsset(from: secondAsset) { second, audioMix, error in
            if let second = second {
                self.mediaPickerRepository.requestAssetVideoWithDefaultOptions(of: firstAsset) { first, audioMix, error in
                    if let first = first {
                        self.movieCombineEditor.combineMovies(first: first, second: second) { result in
                            switch result {
                            case .success(let url):
                                self.saveRecordedMovie(outputUrl: url)
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
    
    func fetchAssets() -> PHFetchResult<PHAsset> {
        return self.mediaPickerRepository.fetchAssets()
    }
    
    func fetchCachingImage(of asset: PHAsset, size: CGSize, resultHandler: @escaping ((UIImage?, [AnyHashable : Any]?) -> Void)) {
        self.mediaPickerRepository.requestCachingImage(of: asset, size: size, resultHandler: resultHandler)
    }
    
}

extension DefaultMediaPickerUseCase {
    
    private func saveRecordedMovie(outputUrl: URL?) {
        guard let outputUrl = outputUrl else { return }
        self.mediaPickerRepository.saveAsset(outputUrl: outputUrl)
    }
    
    private func requestAsset(from phAsset: PHAsset, resultHandler: @escaping (AVAsset?, AVAudioMix?, [AnyHashable : Any]?) -> Void) {
        self.mediaPickerRepository.requestAssetVideoWithDefaultOptions(of: phAsset, resultHandler: resultHandler)
    }
    
}
