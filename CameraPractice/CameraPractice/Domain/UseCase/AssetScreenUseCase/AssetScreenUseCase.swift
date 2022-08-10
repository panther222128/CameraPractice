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
    func requestImage(of asset: PHAsset, size: CGSize, resultHandler: @escaping (UIImage?, [AnyHashable : Any]?) -> Void)
    func requestPlayerItem(of asset: PHAsset, resultHandler: @escaping (AVPlayerItem?, [AnyHashable : Any]?) -> Void)
    func addOverlay(of image: UIImage?, to asset: PHAsset, completion: @escaping (Result<URL?, Error>) -> Void)
    func applyLetterbox(to asset: PHAsset, completion: @escaping (Result<URL?, AssetEditorError>) -> Void)
    func fetchAssets() -> PHFetchResult<PHAsset>
}

final class DefaultAssetScreenUseCase: AssetScreenUseCase {
    
    private let assetScreenRepository: AssetScreenRepository
    private var assetEditor: AssetEditor
    
    init(assetScreenRepository: AssetScreenRepository, assetEditor: AssetEditor) {
        self.assetScreenRepository = assetScreenRepository
        self.assetEditor = assetEditor
    }

    func requestImage(of asset: PHAsset, size: CGSize, resultHandler: @escaping (UIImage?, [AnyHashable : Any]?) -> Void) {
        self.assetScreenRepository.requestImage(of: asset, size: size, resultHandler: resultHandler)
    }
    
    func requestPlayerItem(of asset: PHAsset, resultHandler: @escaping (AVPlayerItem?, [AnyHashable : Any]?) -> Void) {
        self.assetScreenRepository.requestPlayerItem(of: asset, resultHandler: resultHandler)
    }
    
    func addOverlay(of image: UIImage?, to asset: PHAsset, completion: @escaping (Result<URL?, Error>) -> Void) {
        guard let image = image else { return }
        self.requestAsset(of: asset) { asset, audioMix, error in
            if let asset = asset {
                self.assetEditor.addImageOverlay(of: image, to: asset) { result in
                    switch result {
                    case .success(let url):
                        self.saveRecordedMovie(outputUrl: url)
                        completion(.success(url))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    func addTemplate(of url: URL?, to asset: PHAsset, completion: @escaping (Result<URL?, Error>) -> Void) {
        guard let url = url else { return }
        self.requestAsset(of: asset) { asset, audioMix, error in
            self.assetEditor.addTemplate(of: url, to: asset) { result in
                switch result {
                case .success(let url):
                    
                case .failure(let error):
                    
                }
            }
        }
    }
    
    func applyLetterbox(to asset: PHAsset, completion: @escaping (Result<URL?, AssetEditorError>) -> Void) {
        self.requestAsset(of: asset) { asset, audioMix, error in
            if let asset = asset {
                self.assetEditor.applyLetterbox(to: asset) { result in
                    switch result {
                    case .success(let url):
                        self.saveRecordedMovie(outputUrl: url)
                        completion(.success(url))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    func fetchAssets() -> PHFetchResult<PHAsset> {
        return self.assetScreenRepository.fetchAssets()
    }
    
}

extension DefaultAssetScreenUseCase {
    
    private func requestAsset(of asset: PHAsset, resultHandler: @escaping (AVAsset?, AVAudioMix?, [AnyHashable : Any]?) -> Void) {
        self.assetScreenRepository.requestAssetVideoWithDefaultOptions(of: asset, resultHandler: resultHandler)
    }
    
    private func saveRecordedMovie(outputUrl: URL?) {
        guard let outputUrl = outputUrl else { return }
        self.assetScreenRepository.saveAsset(outputUrl: outputUrl)
    }
    
}
