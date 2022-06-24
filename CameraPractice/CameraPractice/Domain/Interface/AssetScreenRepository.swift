//
//  PlaybackRepository.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/14.
//

import Photos
import UIKit

protocol AssetScreenRepository {
    func requestImage(of asset: PHAsset, size: CGSize, resultHandler: @escaping (UIImage?, [AnyHashable : Any]?) -> Void)
    func requestPlayerItem(of asset: PHAsset, resultHandler: @escaping (AVPlayerItem?, [AnyHashable : Any]?) -> Void)
    func requestAVAssetVideoWithDefaultOptions(of asset: PHAsset, resultHandler: @escaping (AVAsset?, AVAudioMix?, [AnyHashable : Any]?) -> Void)
    func fetchAssets() -> PHFetchResult<PHAsset>
    func saveAsset(outputUrl: URL?)
}
