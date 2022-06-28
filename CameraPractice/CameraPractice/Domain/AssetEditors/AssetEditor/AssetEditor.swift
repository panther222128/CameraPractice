//
//  AssetEditor.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/17.
//

import AVFoundation
import UIKit

enum AssetEditorError: Error {
    case insertTimeRangeError
    case assetTrackError
    case exportError
    case mutableCompositionTrackError
    case mutableCompositionError
    
    case trimTimeRangeError
    
    case doesntNeedToApplyLetterbox
}

protocol AssetEditor {
    func addImageOverlay(of image: UIImage?, to asset: AVAsset, completion: @escaping (Result<URL?, AssetEditorError>) -> Void)
    func applyLetterbox(to asset: AVAsset, completion: @escaping (Result<URL?, AssetEditorError>) -> Void)
    func makeLetterbox(to asset: AVAsset, completion: @escaping (Result<URL?, AssetEditorError>) -> Void)
}

final class DefaultAssetEditor: AssetEditor {
    
    private let renderSize = CGSize(width: 1080, height: 1920)
    
    private var mutableComposition: AVMutableComposition
    private var assetTrack: AVAssetTrack?
    private var mutableCompositionTrack: AVMutableCompositionTrack?
    private var backgroundLayer: CALayer
    private var videoLayer: CALayer
    private var overlayLayer: CALayer
    private var outputLayer: CALayer
    private var mutableVideoComposition: AVMutableVideoComposition
    private var mutableVideoCompositionInstruction: AVMutableVideoCompositionInstruction
    
    init() {
        self.mutableComposition = AVMutableComposition()
        self.assetTrack = nil
        self.mutableCompositionTrack = nil
        self.backgroundLayer = CALayer()
        self.videoLayer = CALayer()
        self.overlayLayer = CALayer()
        self.outputLayer = CALayer()
        self.mutableVideoComposition = AVMutableVideoComposition()
        self.mutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
    }
    
    func addImageOverlay(of image: UIImage?, to asset: AVAsset, completion: @escaping (Result<URL?, AssetEditorError>) -> Void) {
        self.addMutableTrack()
        self.getAssetTrack(from: asset)
        switch self.insertTimeRangeToMutableCompositionTrack(asset: asset) {
        case .success(_):
            guard let assetTrack = self.assetTrack else {
                completion(.failure(.insertTimeRangeError))
                return
            }
            guard let mutableCompositionTrack = self.mutableCompositionTrack else { return }
            self.setPreferredTransform(of: mutableCompositionTrack, to: assetTrack)
            let videoOrientation = orientation(from: assetTrack.preferredTransform)
            let videoSize: CGSize
            if videoOrientation.isPortrait {
                videoSize = CGSize(width: assetTrack.naturalSize.height, height: assetTrack.naturalSize.width)
            } else {
                videoSize = assetTrack.naturalSize
            }
            self.setVideoLayer(size: videoSize)
            self.setOverlayLayer(size: videoSize)
            guard let image = image else { return }
            self.addImage(of: image, to: self.overlayLayer, videoSize: videoSize)
            self.setOutputLayer(videoLayer: self.videoLayer, overlayLayer: self.overlayLayer, size: videoSize)
            self.setMutableVideoComposition(size: videoSize, videoLayer: self.videoLayer, outputLayer: self.outputLayer)
            self.setInstructions(mutableComposition: self.mutableComposition, compositionTrack: mutableCompositionTrack)
            self.export(composition: self.mutableComposition, videoComposition: self.mutableVideoComposition) { result in
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
    }
    
    //
    
    private func makeOutputLayer(videoLayer: CALayer, size: CGSize) {
        outputLayer.frame = CGRect(origin: .zero, size: size)
        outputLayer.addSublayer(videoLayer)
    }
    
    func makeLetterbox(to asset: AVAsset, completion: @escaping (Result<URL?, AssetEditorError>) -> Void) {
        self.getAssetTrack(from: asset)
        self.addMutableTrack()
        switch self.insertTimeRangeToMutableCompositionTrack(asset: asset) {
        case .success(let assetTrack):
            guard let mutableCompositionTrack = self.mutableCompositionTrack else {
                completion(.failure(.mutableCompositionTrackError))
                return
            }
            self.setVideoLayer(size: self.renderSize)
            self.makeOutputLayer(videoLayer: self.videoLayer, size: self.renderSize)
            
            self.setMutableVideoComposition(size: self.renderSize, videoLayer: self.videoLayer, outputLayer: self.outputLayer)
            
            self.setLetterboxInstructions(asset: asset, mutableComposition: self.mutableComposition, compositionTrack: mutableCompositionTrack)
            
            self.export(composition: self.mutableComposition, videoComposition: self.mutableVideoComposition) { result in
                switch result {
                case .success(let url):
                    completion(.success(url))
                case .failure(let error):
                    print(error)
                    completion(.failure(error))
                }
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }
    
    func applyLetterbox(to asset: AVAsset, completion: @escaping (Result<URL?, AssetEditorError>) -> Void) {
        self.getAssetTrack(from: asset)
        guard let ratio = self.checkAssetTrackRatio() else { return }
        self.addMutableTrack()
        if ratio < 0.5625 {
            guard let assetTrack = self.assetTrack else {
                completion(.failure(.assetTrackError))
                return
            }
            
            self.backgroundLayer.frame = CGRect(x: 0, y: 0, width: assetTrack.naturalSize.height * 0.5625, height: assetTrack.naturalSize.height)
            self.backgroundLayer.backgroundColor = UIColor.black.cgColor
            
            switch self.insertTimeRangeToMutableCompositionTrack(asset: asset) {
            case .success(let assetTrack):
                guard let assetTrack = self.assetTrack else {
                    completion(.failure(.insertTimeRangeError))
                    return
                }
                guard let mutableCompositionTrack = self.mutableCompositionTrack else { return }
                self.setPreferredTransform(of: mutableCompositionTrack, to: assetTrack)
                let videoSize: CGSize
                videoSize = CGSize(width: assetTrack.naturalSize.width, height: assetTrack.naturalSize.width / 0.5625)
                self.setVideoLayer(size: videoSize)
                self.setBackgroundLayer(videoLayer: self.videoLayer, backgroundLayer: self.backgroundLayer, size: videoSize)
                self.setOutputLayer(videoLayer: self.videoLayer, overlayLayer: self.overlayLayer, size: videoSize)
                self.setMutableVideoComposition(size: videoSize, videoLayer: self.videoLayer, outputLayer: self.outputLayer)
                self.setInstructions(mutableComposition: self.mutableComposition, compositionTrack: mutableCompositionTrack)
                self.export(composition: self.mutableComposition, videoComposition: self.mutableVideoComposition) { result in
                    switch result {
                    case .success(let url):
                        completion(.success(url))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(.insertTimeRangeError))
            }
        } else if ratio > 0.5625 {
            guard let assetTrack = assetTrack else {
                completion(.failure(.assetTrackError))
                return
            }
            self.backgroundLayer.frame = CGRect(x: 0, y: 0, width: assetTrack.naturalSize.width, height: assetTrack.naturalSize.height / 0.5625)
            self.backgroundLayer.backgroundColor = UIColor.black.cgColor
            
            switch self.insertTimeRangeToMutableCompositionTrack(asset: asset) {
            case .success(let assetTrack):
                guard let assetTrack = self.assetTrack else {
                    completion(.failure(.insertTimeRangeError))
                    return
                }
                guard let mutableCompositionTrack = self.mutableCompositionTrack else { return }
                self.setPreferredTransform(of: mutableCompositionTrack, to: assetTrack)
                let videoSize: CGSize
                videoSize = CGSize(width: assetTrack.naturalSize.width, height: assetTrack.naturalSize.height / 0.5625)
                self.setVideoLayer(size: videoSize)
                self.setBackgroundLayer(videoLayer: self.videoLayer, backgroundLayer: self.backgroundLayer, size: videoSize)
                self.setOutputLayer(videoLayer: self.videoLayer, overlayLayer: self.overlayLayer, size: videoSize)
                
                self.setMutableVideoComposition(size: videoSize, videoLayer: self.videoLayer, outputLayer: self.outputLayer)
                self.setInstructions(mutableComposition: self.mutableComposition, compositionTrack: mutableCompositionTrack)
                self.export(composition: self.mutableComposition, videoComposition: self.mutableVideoComposition) { result in
                    switch result {
                    case .success(let url):
                        completion(.success(url))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(.insertTimeRangeError))
            }
        } else {
            completion(.failure(.doesntNeedToApplyLetterbox))
        }
    }
    
}

extension DefaultAssetEditor {
    
    private func addMutableTrack() {
        self.mutableCompositionTrack = self.mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        self.mutableVideoComposition.renderSize = self.renderSize
        self.mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
    }
    
    private func getAssetTrack(from asset: AVAsset) {
        guard let assetTrack = asset.tracks(withMediaType: .video).first else { return }
        self.assetTrack = assetTrack
    }
    
    private func insertTimeRangeToMutableCompositionTrack(asset: AVAsset) -> Result<AVAssetTrack, AssetEditorError> {
        guard let mutableCompositionTrack = self.mutableCompositionTrack else {
            return .failure(.mutableCompositionTrackError)
        }
        do {
            let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            guard let assetTrack = self.assetTrack else {
                return .failure(.assetTrackError)
            }
            try mutableCompositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
            if let audioAssetTrack = asset.tracks(withMediaType: .audio).first, let compositionAudioTrack = self.mutableComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                try compositionAudioTrack.insertTimeRange(timeRange, of: audioAssetTrack, at: .zero)
                return .success(audioAssetTrack)
            } else {
                return .failure(.insertTimeRangeError)
            }
        } catch {
            return .failure(.insertTimeRangeError)
        }
    }
    
    private func setVideoLayer(size: CGSize) {
        videoLayer.frame = CGRect(origin: .zero, size: size)
    }
    
    private func setOverlayLayer(size: CGSize) {
        overlayLayer.frame = CGRect(origin: .zero, size: size)
    }
    
    private func setBackgroundLayer(videoLayer: CALayer, backgroundLayer: CALayer, size: CGSize) {
        outputLayer.frame = CGRect(origin: .zero, size: size)
        videoLayer.position.y = backgroundLayer.position.y / 2
        outputLayer.addSublayer(backgroundLayer)
        outputLayer.addSublayer(videoLayer)
    }
    
    private func setOutputLayer(videoLayer: CALayer, overlayLayer: CALayer, size: CGSize) {
        outputLayer.frame = CGRect(origin: .zero, size: size)
        outputLayer.addSublayer(videoLayer)
        outputLayer.addSublayer(overlayLayer)
    }
    
    private func setMutableVideoComposition(size: CGSize, videoLayer: CALayer, outputLayer: CALayer) {
        self.mutableVideoComposition.renderSize = size
        self.mutableVideoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        self.mutableVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: outputLayer)
    }
    
    private func setInstructions(mutableComposition: AVMutableComposition, compositionTrack: AVMutableCompositionTrack) {
        self.mutableVideoCompositionInstruction.timeRange = CMTimeRange(start: .zero, duration: mutableComposition.duration)
        self.mutableVideoComposition.instructions = [mutableVideoCompositionInstruction]
        guard let assetTrack = self.assetTrack else { return }
        let layerInstruction = compositionLayerInstruction(for: compositionTrack, assetTrack: assetTrack)
        self.mutableVideoCompositionInstruction.layerInstructions = [layerInstruction]
    }
    
    private func setLetterboxInstructions(asset: AVAsset, mutableComposition: AVMutableComposition, compositionTrack: AVMutableCompositionTrack) {
        self.mutableVideoCompositionInstruction.timeRange = CMTimeRange(start: .zero, duration: mutableComposition.duration)
        self.mutableVideoComposition.instructions = [mutableVideoCompositionInstruction]
        guard let assetTrack = self.assetTrack else { return }
        let layerInstruction = setLetterboxVideoCompositionLayerInstruction(asset: asset, compositionTrack: compositionTrack, assetTrack: assetTrack)
        self.mutableVideoCompositionInstruction.layerInstructions = [layerInstruction]
    }
    
    private func setPreferredTransform(of compositionTrack: AVMutableCompositionTrack, to assetTrack: AVAssetTrack) {
        compositionTrack.preferredTransform = assetTrack.preferredTransform
    }
    
    private func orientation(from transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == 1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .rightMirrored
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .leftMirrored
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        
        return (assetOrientation, isPortrait)
    }
    
    private func addImage(of image: UIImage?, to layer: CALayer, videoSize: CGSize) {
        guard let image = image else { return }
        let imageLayer = CALayer()
        
        let aspect: CGFloat = image.size.width / image.size.height
        let width = videoSize.width
        let height = width / aspect
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
    
    private func setLetterboxVideoCompositionLayerInstruction(asset: AVAsset, compositionTrack: AVMutableCompositionTrack, assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction {
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: assetTrack)
        let fixedPreferredTransform = assetTrack.fixedPreferredTransform
        let assetTrackOrientation = orientationFromTransform(fixedPreferredTransform)
        
        if assetTrackOrientation.isPortrait {
            let scaleToFitRatio = self.renderSize.width / assetTrack.naturalSize.height
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            var transformed = assetTrack.fixedPreferredTransform.concatenating(scaleFactor)
            
            if assetTrackOrientation.orientation == .rightMirrored || assetTrackOrientation.orientation == .leftMirrored {
                transformed = transformed.translatedBy(x: -fixedPreferredTransform.ty, y: 0)
            }
            layerInstruction.setTransform(transformed, at: .zero)
        } else {
            let renderRect = CGRect(x: 0, y: 0, width: self.renderSize.width, height: self.renderSize.height)
            let videoRect = CGRect(origin: .zero, size: assetTrack.naturalSize).applying(assetTrack.fixedPreferredTransform)

            let scale = renderRect.width / videoRect.width
            let transform = CGAffineTransform(scaleX: renderRect.width / videoRect.width, y: (videoRect.height * scale) / assetTrack.naturalSize.height)
            let translate = CGAffineTransform(translationX: .zero, y: ((self.renderSize.height - (videoRect.height * scale))) / 2)

            layerInstruction.setTransform(assetTrack.fixedPreferredTransform.concatenating(transform).concatenating(translate), at: .zero)
        }
        
        layerInstruction.setOpacity(0, at: asset.duration)
        
        return layerInstruction
    }
    
    private func export(composition: AVMutableComposition, videoComposition: AVMutableVideoComposition, completion: @escaping (Result<URL?, AssetEditorError>) -> Void) {
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(.exportError))
            return
        }
        let videoName = UUID().uuidString
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(videoName).appendingPathExtension("mp4")
        exportSession.videoComposition = videoComposition
        exportSession.outputFileType = .mp4
        exportSession.outputURL = exportURL
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    completion(.success(exportURL))
                default:
                    completion(.failure(.exportError))
                    break
                }
            }
        }
    }
    
    private func exportTrimmedAsset(from asset: AVAsset, timeRange: CMTimeRange, completion: @escaping (Result<URL?, AssetEditorError>) -> Void) {
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(.exportError))
            return
        }
        let videoName = UUID().uuidString
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(videoName).appendingPathExtension("mp4")
        exportSession.outputFileType = .mp4
        exportSession.outputURL = exportURL
        exportSession.timeRange = timeRange
        
        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    completion(.success(exportURL))
                default:
                    completion(.failure(.exportError))
                    break
                }
            }
        }
    }
    
    private func checkAssetTrackRatio() -> CGFloat? {
        guard let assetTrack = assetTrack else { return nil }
        let width = assetTrack.naturalSize.width
        let height = assetTrack.naturalSize.height
        
        let ratio = width / height
        
        return ratio
    }
    
}

extension DefaultAssetEditor {

    func orientationFromTransform(_ transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == 1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .rightMirrored
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .leftMirrored
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }
    
}
