//
//  MediaPickerUseCase.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/13.
//

import AVFoundation
import UIKit

protocol MediaPickerUseCase {
    func combineMovies(first: AVAsset, second: AVAsset, completion: @escaping (Result<URL?, Error>) -> Void)
    func saveRecordedMovie(outputUrl: URL?)
}

final class DefaultMediaPickerUseCase: MediaPickerUseCase {

    private var movieCombineEditor: MovieCombineEditor
    
    init(movieCombineEditor: MovieCombineEditor) {
        self.movieCombineEditor = movieCombineEditor
    }
    
    func combineMovies(first: AVAsset, second: AVAsset, completion: @escaping (Result<URL?, Error>) -> Void) {
        movieCombineEditor.combineMovies(first: first, second: second) { result in
            switch result {
            case .success(let url):
                completion(.success(url))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func saveRecordedMovie(outputUrl: URL?) {
        guard let outputUrl = outputUrl else { return }
        let recordedMovieUrl = outputUrl as URL
        UISaveVideoAtPathToSavedPhotosAlbum(recordedMovieUrl.path, nil, nil, nil)
    }
    
}
