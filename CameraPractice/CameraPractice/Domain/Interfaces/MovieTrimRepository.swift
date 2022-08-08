//
//  MovieTrimRepository.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/21.
//

import Photos

protocol MovieTrimRepository {
    func requestAVAssetVideoWithDefaultOptions(of asset: PHAsset, resultHandler: @escaping (AVAsset?, AVAudioMix?, [AnyHashable : Any]?) -> Void)
    func fetchAssets() -> PHFetchResult<PHAsset>
    func saveAsset(outputUrl: URL?)
}
