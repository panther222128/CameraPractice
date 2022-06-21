//
//  PlaybackUseCase.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/13.
//

import AVFoundation
import Photos
import UIKit

protocol AssetScreenUseCase {
    func addOverlay(to asset: AVAsset, completion: @escaping (Result<URL?, Error>) -> Void)
    func saveRecordedMovie(outputUrl: URL?)
}

final class DefaultAssetScreenUseCase: AssetScreenUseCase {
    
    private var assetEditor: AssetEditor?
    
    init(assetEditor: AssetEditor) {
        self.assetEditor = nil
    }
    
    func addOverlay(to asset: AVAsset, completion: @escaping (Result<URL?, Error>) -> Void) {
        self.assetEditor = DefaultAssetEditor()
        guard let assetEditor = self.assetEditor else { return }
        assetEditor.addImageOverlay(to: asset) { result in
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
        self.assetEditor = nil
    }
    
}
