//
//  AssetEditor.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/17.
//

import AVFoundation
import UIKit

enum AssetEditorError: Error {
    case instantiateMutableCompositionError
    case compositionTrackError
    case addMutableTrackError
    case assetTrackError
    case insertTimeRangeError
    case exportError
    case instantiateVideoLayerError
    case instantiateOutputLayerError
    case setVideoLayerError
    case setOverlayLayerError
    case setOutputLayerError
    case mutableVideoCompositionError
    case setInstructionError
}

protocol AssetEditor {
    func addOverlay(to asset: AVAsset, completion: @escaping (Result<URL?, AssetEditorError>) -> Void)
    func addImageOverlay(to asset: AVAsset, completion: @escaping (Result<URL?, AssetEditorError>) -> Void)
}

final class DefaultAssetEditor: AssetEditor {
    
    private var mutableComposition: AVMutableComposition?
    private var assetTrack: AVAssetTrack?
    private var videoLayer: CALayer?
    private var overlayLayer: CALayer?
    private var outputLayer: CALayer?
    private var mutableVideoComposition: AVMutableVideoComposition?
    private var mutableVideoCompositionInstruction: AVMutableVideoCompositionInstruction?
    
    init() {
        self.mutableComposition = nil
        self.assetTrack = nil
        self.videoLayer = nil
        self.overlayLayer = nil
        self.outputLayer = nil
        self.mutableVideoComposition = nil
        self.mutableVideoCompositionInstruction = nil
    }
    
    private func instantiateMutableComposition() {
        self.mutableComposition = AVMutableComposition()
    }
    
    private func addMutableTrack() -> Result<AVMutableCompositionTrack, AssetEditorError> {
        guard let mutableComposition = self.mutableComposition else {
            return .failure(.instantiateMutableCompositionError)
        }
        guard let mutableCompositionTrack = mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            return .failure(.addMutableTrackError)
        }
        return .success(mutableCompositionTrack)
    }
    
    private func getAssetTrack(from asset: AVAsset) -> Result<AVAssetTrack, AssetEditorError> {
        guard let assetTrack = asset.tracks(withMediaType: .video).first else {
            return .failure(.assetTrackError)
        }
        self.assetTrack = assetTrack
        return .success(assetTrack)
    }
    
    private func insertTimeRangeToMutableCompositionTrack(asset: AVAsset, mutableComposition: AVMutableComposition, mutableCompositionTrack: AVMutableCompositionTrack) -> Result<AVAssetTrack, AssetEditorError> {
        do {
            let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            guard let assetTrack = self.assetTrack else {
                return .failure(.assetTrackError)
            }
            try mutableCompositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
            if let audioAssetTrack = asset.tracks(withMediaType: .audio).first, let compositionAudioTrack = mutableComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                try compositionAudioTrack.insertTimeRange(timeRange, of: audioAssetTrack, at: .zero)
                return .success(audioAssetTrack)
            } else {
                return .failure(.insertTimeRangeError)
            }
        } catch {
            return .failure(.insertTimeRangeError)
        }
    }
    
    private func setVideoLayer(size: CGSize) -> Result<CALayer, AssetEditorError> {
        self.videoLayer = CALayer()
        guard let videoLayer = self.videoLayer else {
            return .failure(.setVideoLayerError)
        }
        videoLayer.frame = CGRect(origin: .zero, size: size)
        return .success(videoLayer)
    }
    
    private func setOverlayLayer(size: CGSize) -> Result<CALayer, AssetEditorError> {
        self.overlayLayer = CALayer()
        guard let overlayLayer = self.overlayLayer else {
            return .failure(.setOverlayLayerError)
        }
        overlayLayer.frame = CGRect(origin: .zero, size: size)
        return .success(overlayLayer)
    }
    
    private func setOutputLayer(videoLayer: CALayer, overlayLayer: CALayer, size: CGSize) -> Result<CALayer, AssetEditorError> {
        self.outputLayer = CALayer()
        guard let outputLayer = self.outputLayer else {
            return .failure(.setOutputLayerError)
        }
        outputLayer.frame = CGRect(origin: .zero, size: size)
        outputLayer.addSublayer(videoLayer)
        outputLayer.addSublayer(overlayLayer)
        return .success(outputLayer)
    }
    
    private func setMutableVideoComposition(size: CGSize, videoLayer: CALayer, outputLayer: CALayer) -> Result<AVMutableVideoComposition, AssetEditorError> {
        self.mutableVideoComposition = AVMutableVideoComposition()
        guard let mutableVideoComposition = self.mutableVideoComposition else {
            return .failure(.mutableVideoCompositionError)
        }
        mutableVideoComposition.renderSize = size
        mutableVideoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        mutableVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: outputLayer)
        return .success(mutableVideoComposition)
    }
    
    private func setInstructions(mutableComposition: AVMutableComposition, mutableVideoComposition: AVMutableVideoComposition, compositionTrack: AVMutableCompositionTrack) -> Result<AVMutableVideoCompositionInstruction, AssetEditorError> {
        self.mutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        guard let mutableVideoCompositionInstruction = self.mutableVideoCompositionInstruction else {
            return .failure(.setInstructionError)
        }
        mutableVideoCompositionInstruction.timeRange = CMTimeRange(start: .zero, duration: mutableComposition.duration)
        mutableVideoComposition.instructions = [mutableVideoCompositionInstruction]
        
        guard let assetTrack = self.assetTrack else {
            return .failure(.assetTrackError)
        }
        
        let layerInstruction = compositionLayerInstruction(for: compositionTrack, assetTrack: assetTrack)
        mutableVideoCompositionInstruction.layerInstructions = [layerInstruction]
        
        return .success(mutableVideoCompositionInstruction)
    }
    
    private func setPreferredTransform(of compositionTrack: AVMutableCompositionTrack, to assetTrack: AVAssetTrack) {
        compositionTrack.preferredTransform = assetTrack.preferredTransform
    }
    
    func addImageOverlay(to asset: AVAsset, completion: @escaping (Result<URL?, AssetEditorError>) -> Void) {
        self.instantiateMutableComposition()
        
        if let mutableComposition = self.mutableComposition {
            switch self.addMutableTrack() {
            case .success(let mutableCompositionTrack):
                switch self.getAssetTrack(from: asset) {
                case .success(let assetTrack):
                    switch self.insertTimeRangeToMutableCompositionTrack(asset: asset, mutableComposition: mutableComposition, mutableCompositionTrack: mutableCompositionTrack) {
                    case .success(let assetTrack):
                        guard let assetTrack = self.assetTrack else {
                            return completion(.failure(.assetTrackError))
                        }
                        self.setPreferredTransform(of: mutableCompositionTrack, to: assetTrack)
                        let videoOrientation = orientation(from: assetTrack.preferredTransform)
                        let videoSize: CGSize
                        if videoOrientation.isPortrait {
                            videoSize = CGSize(width: assetTrack.naturalSize.height, height: assetTrack.naturalSize.width)
                        } else {
                            videoSize = assetTrack.naturalSize
                        }
                        switch self.setVideoLayer(size: videoSize) {
                        case .success(let videoLayer):
                            switch self.setOverlayLayer(size: videoSize) {
                            case .success(let overlayLayer):
                                self.addImage(to: overlayLayer, videoSize: videoSize)
                                switch self.setOutputLayer(videoLayer: videoLayer, overlayLayer: overlayLayer, size: videoSize) {
                                case .success(let outputLayer):
                                    switch self.setMutableVideoComposition(size: videoSize, videoLayer: videoLayer, outputLayer: outputLayer) {
                                    case .success(let mutableVideoComposition):
                                        switch self.setInstructions(mutableComposition: mutableComposition, mutableVideoComposition: mutableVideoComposition, compositionTrack: mutableCompositionTrack) {
                                        case .success(let instruction):
                                            self.export(composition: mutableComposition, videoComposition: mutableVideoComposition) { result in
                                                switch result {
                                                case .success(let url):
                                                    completion(.success(url))
                                                case .failure(let error):
                                                    completion(.failure(error))
                                                }
                                            }
                                        case .failure(let error):
                                            completion(.failure(error))
                                        }
                                    case .failure(let error):
                                        completion(.failure(error))
                                    }
                                case .failure(let error):
                                    completion(.failure(error))
                                }
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        } else {
            completion(.failure(.instantiateMutableCompositionError))
        }
    }
    
    func addOverlay(to asset: AVAsset, completion: @escaping (Result<URL?, AssetEditorError>) -> Void) {
        // 1. Instantiate AVMutableComposition
        let composition = AVMutableComposition()
        
        // 2. composition addMutableTrack
        guard let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(.failure(.addMutableTrackError))
            return
        }
        
        // 3. get track from asset
        guard let assetTrack = asset.tracks(withMediaType: .video).first else {
            completion(.failure(.assetTrackError))
            return
        }
        
        // 4. insert TimeRange to compositionAudioTrack
        do {
            let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
            if let audioAssetTrack = asset.tracks(withMediaType: .audio).first, let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                try compositionAudioTrack.insertTimeRange(timeRange, of: audioAssetTrack, at: .zero)
            }
        } catch {
            completion(.failure(.insertTimeRangeError))
        }
        
        // 5. set preferredTransform
        compositionTrack.preferredTransform = assetTrack.preferredTransform
        
        // 6. get video orientation
        let videoInfo = orientation(from: assetTrack.preferredTransform)
        
        // 7. Sizing
        let videoSize: CGSize
        if videoInfo.isPortrait {
            videoSize = CGSize(width: assetTrack.naturalSize.height, height: assetTrack.naturalSize.width)
        } else {
            videoSize = assetTrack.naturalSize
        }
        
        // 8. input layer
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)
        
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(origin: .zero, size: videoSize)
        
        // 9. add Image
        addImage(to: overlayLayer, videoSize: videoSize)
        
        // 10. outputLayer
        let outputLayer = CALayer()
        outputLayer.frame = CGRect(origin: .zero, size: videoSize)
        outputLayer.addSublayer(videoLayer)
        outputLayer.addSublayer(overlayLayer)
        
        // 11. AVMutableVideoComposition
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: outputLayer)
        
        // 12. AVMutableVideoCompositionInstruction
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
        videoComposition.instructions = [instruction]
        let layerInstruction = compositionLayerInstruction(for: compositionTrack, assetTrack: assetTrack)
        instruction.layerInstructions = [layerInstruction]
        
        // 13. export
        self.export(composition: composition, videoComposition: videoComposition) { result in
            switch result {
            case .success(let url):
                completion(.success(url))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func export(composition: AVMutableComposition, videoComposition: AVMutableVideoComposition, completion: @escaping (Result<URL?, AssetEditorError>) -> Void) {
        guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(.exportError))
            return
        }
        let videoName = UUID().uuidString
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(videoName).appendingPathExtension("mp4")
        export.videoComposition = videoComposition
        export.outputFileType = .mp4
        export.outputURL = exportURL
        
        export.exportAsynchronously {
            DispatchQueue.main.async {
                switch export.status {
                case .completed:
                    completion(.success(exportURL))
                default:
                    completion(.failure(.exportError))
                    break
                }
            }
        }
    }
    
}

extension DefaultAssetEditor {
    
    private func orientation(from transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        
        return (assetOrientation, isPortrait)
    }
    
    private func addImage(to layer: CALayer, videoSize: CGSize) {
        guard let image = UIImage(named: "overlay") else { return }
        let imageLayer = CALayer()
        
        let aspoect: CGFloat = image.size.width / image.size.height
        let width = videoSize.width
        let height = width / aspoect
        imageLayer.frame = CGRect(x: 0, y: -height * 0.15, width: width, height: height)
        
        imageLayer.contents = image.cgImage
        layer.addSublayer(imageLayer)
    }
    
    private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let transform = assetTrack.preferredTransform
        
        instruction.setTransform(transform, at: .zero)
        
        return instruction
    }
    
}
