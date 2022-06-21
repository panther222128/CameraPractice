//
//  MovieTrimViewModel.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/21.
//

import AVFoundation

protocol MovieTrimViewModel {
    var trimTimeRange: Observable<TrimTimeRange> { get }
    
    func didTrimMovie(of asset: AVAsset, from startTime: Float, to endTime: Float, completion: @escaping (Result<URL?, MovieTrimEditorError>) -> Void)
}

final class DefaultMovieTrimViewModel: MovieTrimViewModel {
    
    private let movieTrimUseCase: MovieTrimUseCase
    private let assetIndex: Int
    let trimTimeRange: Observable<TrimTimeRange>
    
    init(movieTrimUseCase: MovieTrimUseCase, assetIndex: Int) {
        self.movieTrimUseCase = movieTrimUseCase
        self.assetIndex = assetIndex
        self.trimTimeRange = Observable(TrimTimeRange(startTime: nil, endTime: nil))
    }
    
    func didTrimMovie(of asset: AVAsset, from startTime: Float, to endTime: Float, completion: @escaping (Result<URL?, MovieTrimEditorError>) -> Void) {
        self.movieTrimUseCase.trimMovie(of: asset, from: startTime, to: endTime) { result in
            switch result {
            case .success(let url):
                completion(.success(url))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}
