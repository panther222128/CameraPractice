//
//  MovieTrimUseCase.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/21.
//

import AVFoundation
import UIKit
import Photos

protocol MovieTrimUseCase {
    func fetchAssets() -> PHFetchResult<PHAsset>
    func trimMovie(of asset: PHAsset, from startTime: Float, to endTime: Float, completion: @escaping (Result<URL?, MovieTrimEditorError>) -> Void)
}

final class DefaultMovieTrimUseCase: MovieTrimUseCase {
    
    private let movieTrimRepository: MovieTrimRepository
    private var movieTrimEditor: MovieTrimEditor
    
    init(movieTrimRepository: MovieTrimRepository, movieTrimEditor: MovieTrimEditor) {
        self.movieTrimRepository = movieTrimRepository
        self.movieTrimEditor = movieTrimEditor
    }
    
    func fetchAssets() -> PHFetchResult<PHAsset> {
        return self.movieTrimRepository.fetchAssets()
    }
    
    func trimMovie(of asset: PHAsset, from startTime: Float, to endTime: Float, completion: @escaping (Result<URL?, MovieTrimEditorError>) -> Void) {
        self.movieTrimRepository.requestAVAssetVideoWithDefaultOptions(of: asset) { asset, audioMix, error in
            if let asset = asset {
                self.movieTrimEditor.trimMovie(of: asset, from: startTime, to: endTime) { result in
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

extension DefaultMovieTrimUseCase {
    
    private func saveRecordedMovie(outputUrl: URL?) {
        guard let outputUrl = outputUrl else { return }
        self.movieTrimRepository.saveAsset(outputUrl: outputUrl)
    }
    
}
