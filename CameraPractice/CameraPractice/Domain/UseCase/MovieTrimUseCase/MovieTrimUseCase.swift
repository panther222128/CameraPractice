//
//  MovieTrimUseCase.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/21.
//

import AVFoundation

protocol MovieTrimUseCase {
    func trimMovie(of asset: AVAsset, from startTime: Float, to endTime: Float, completion: @escaping (Result<URL?, MovieTrimEditorError>) -> Void)
}

final class DefaultMovieTrimUseCase: MovieTrimUseCase {
    
    private var movieTrimEditor: MovieTrimEditor?
    
    init(movieTrimEditor: MovieTrimEditor) {
        self.movieTrimEditor = nil
    }
    
    func trimMovie(of asset: AVAsset, from startTime: Float, to endTime: Float, completion: @escaping (Result<URL?, MovieTrimEditorError>) -> Void) {
        self.movieTrimEditor = DefaultMovieTrimEditor()
        guard let movieTrimEditor = self.movieTrimEditor else { return }
        movieTrimEditor.trimMovie(of: asset, from: startTime, to: endTime, completion: { result in
            switch result {
            case .success(let url):
                completion(.success(url))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
    
}
