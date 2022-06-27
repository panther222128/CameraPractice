//
//  DefaultMovieTrimRepository.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/21.
//

import UIKit
import Photos

final class DefaultMovieTrimRepository: MovieTrimRepository {
    
    private let imageManager: ImageManager
    
    init(imageManager: ImageManager) {
        self.imageManager = imageManager
    }
    
    func requestAVAssetVideoWithDefaultOptions(of asset: PHAsset, resultHandler: @escaping (AVAsset?, AVAudioMix?, [AnyHashable : Any]?) -> Void) {
        self.imageManager.requestAssetVideoWithDefaultOptions(for: asset, resultHandler: resultHandler)
    }
    
    func fetchAssets() -> PHFetchResult<PHAsset> {
        return PHAsset.fetchAssets(with: nil)
    }
    
    func saveAsset(outputUrl: URL?) {
        guard let outputUrl = outputUrl else { return }
        let recordedMovieUrl = outputUrl as URL
        UISaveVideoAtPathToSavedPhotosAlbum(recordedMovieUrl.path, nil, nil, nil)
    }
    
}
