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
    func addOverlay(to asset: AVAsset, completion: @escaping (URL?) -> Void)
    func saveRecordedMovie(outputUrl: URL?)
}

final class DefaultAssetScreenUseCase: AssetScreenUseCase {
    
    private let assetEditor: AssetEditor
    
    init(assetEditor: AssetEditor) {
        self.assetEditor = assetEditor
    }
    
    func addOverlay(to asset: AVAsset, completion: @escaping (URL?) -> Void) {
        self.assetEditor.addOverlay(to: asset) { url in
            if let url = url {
                completion(url)
            } else {
                completion(nil)
            }
        }
    }
    
    func saveRecordedMovie(outputUrl: URL?) {
        guard let outputUrl = outputUrl else { return }
        let recordedMovieUrl = outputUrl as URL
        UISaveVideoAtPathToSavedPhotosAlbum(recordedMovieUrl.path, nil, nil, nil)
    }
    
}