//
//  MediaPickerRepository.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/13.
//

import Photos
import UIKit

protocol MediaPickerRepository {
    func requestAVAssetVideoWithDefaultOptions(of asset: PHAsset, resultHandler: @escaping (AVAsset?, AVAudioMix?, [AnyHashable : Any]?) -> Void)
    func fetchAssets() -> PHFetchResult<PHAsset>
    func saveAsset(outputUrl: URL?)
    func requestCachingImage(of asset: PHAsset, size: CGSize, resultHandler: @escaping ((UIImage?, [AnyHashable : Any]?) -> Void))
}
