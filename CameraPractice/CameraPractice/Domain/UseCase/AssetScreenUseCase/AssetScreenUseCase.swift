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
    func addOverlay(of image: UIImage?, to asset: AVAsset, completion: @escaping (Result<URL?, Error>) -> Void)
    func saveRecordedMovie(url: URL?)
}

final class DefaultAssetScreenUseCase: AssetScreenUseCase {
    
    private var assetEditor: AssetEditor
    
    init(assetEditor: AssetEditor) {
        self.assetEditor = assetEditor
    }
    
    func addOverlay(of image: UIImage?, to asset: AVAsset, completion: @escaping (Result<URL?, Error>) -> Void) {
        guard let image = image else { return }
        assetEditor.addImageOverlay(of: image, to: asset) { result in
            switch result {
            case .success(let url):
                completion(.success(url))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func saveRecordedMovie(url: URL?) {
        guard let url = url else { return }
        let recordedMovieUrl = url as URL
        UISaveVideoAtPathToSavedPhotosAlbum(recordedMovieUrl.path, nil, nil, nil)
    }
    
}
