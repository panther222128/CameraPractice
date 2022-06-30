//
//  MovieCombineEditor.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/22.
//

import AVFoundation
import UIKit

enum MovieCombineError: Error {
    case mutableCompositionTrackError
    case insertTimeRangeError
    case assetTrackError
    case exportError
}

protocol MovieCombineEditor {
    func combineMovies(first: AVAsset, second: AVAsset, completion: @escaping (Result<URL?, MovieCombineError>) -> Void)
}

final class DefaultMovieCombineEditor: MovieCombineEditor {
    
    private let renderSize = CGSize(width: 1080, height: 1920)
    private var mutableComposition: AVMutableComposition
    private var mutableCompositionTrack: AVMutableCompositionTrack?
    private var mutableVideoComposition: AVMutableVideoComposition
    private var currentDuration: CMTime
    private var mutableVideoCompositionInstruction: AVMutableVideoCompositionInstruction
    
    init() {
        self.mutableComposition = AVMutableComposition()
        self.mutableCompositionTrack = nil
        self.mutableVideoComposition = AVMutableVideoComposition()
        self.currentDuration = CMTime()
        self.mutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
    }

    func combineMovies(first: AVAsset, second: AVAsset, completion: @escaping (Result<URL?, MovieCombineError>) -> Void) {
        guard let mutableVideoTrack = self.mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(.failure(.insertTimeRangeError))
            return
        }
        guard let mutableAudioTrack = self.mutableComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(.failure(.insertTimeRangeError))
            return
        }
        self.setMutableVideoComposition()
        do {
            try self.insertTimeRange(of: first, mutableVideoTrack: mutableVideoTrack, mutableAudioTrack: mutableAudioTrack)
        } catch {
            completion(.failure(.insertTimeRangeError))
            return
        }
        self.setDuration(of: first)
        do {
            try self.insertTimeRange(of: second, mutableVideoTrack: mutableVideoTrack, mutableAudioTrack: mutableAudioTrack)
        } catch {
            completion(.failure(.insertTimeRangeError))
            return
        }
        self.setDuration(of: second)
        self.setPreferredTransform(of: first, mutableVideoTrack: mutableVideoTrack, mutableAudioTrack: mutableAudioTrack)
        self.setPreferredTransform(of: second, mutableVideoTrack: mutableVideoTrack, mutableAudioTrack: mutableAudioTrack)
        self.export(composition: self.mutableComposition) { result in
            switch result {
            case .success(let url):
                self.currentDuration = CMTime()
                completion(.success(url))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}

extension DefaultMovieCombineEditor {
    
    private func makeLetterbox(to asset: AVAsset) throws -> Result<AVMutableCompositionTrack?, MovieCombineError> {
        guard let mutableVideoTrack = self.mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { return .failure(.mutableCompositionTrackError) }
        guard let mutableAudioTrack = self.mutableComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { return .failure(.mutableCompositionTrackError) }
        do {
            try self.insertTimeRange(of: asset, mutableVideoTrack: mutableVideoTrack, mutableAudioTrack: mutableAudioTrack)
            
        } catch {
            return .failure(.insertTimeRangeError)
        }
        
        let videoLayer: CALayer? = CALayer()
        if let videoLayer = videoLayer {
            self.setVideoLayer(to: videoLayer, size: self.renderSize)
        }
        
        let outputLayer: CALayer? = CALayer()
        if let outputLayer = outputLayer {
            self.setLetterboxOutputLayer(outputLayer: outputLayer, videoLayer: videoLayer ?? CALayer(), size: self.renderSize)
        }
        self.setMutableVideoComposition(size: self.renderSize, videoLayer: videoLayer ?? CALayer(), outputLayer: outputLayer ?? CALayer())
        self.setLetterboxInstructions(asset: asset, mutableComposition: self.mutableComposition, compositionTrack: mutableVideoTrack)
        self.export(composition: self.mutableComposition) { result in
            switch result {
            case .success(let url):
                return .success(mutableVideoTrack)
            case .failure(let error):
            }
        }
    }
    
    private func setVideoLayer(to layer: CALayer, size: CGSize) {
        layer.frame = CGRect(origin: .zero, size: size)
    }
    
    private func setMutableVideoComposition(size: CGSize, videoLayer: CALayer, outputLayer: CALayer) {
        self.mutableVideoComposition.renderSize = size
        self.mutableVideoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        self.mutableVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: outputLayer)
    }
    
    private func setLetterboxOutputLayer(outputLayer: CALayer, videoLayer: CALayer, size: CGSize) {
        outputLayer.frame = CGRect(origin: .zero, size: size)
        outputLayer.addSublayer(videoLayer)
    }
    
    private func validateIsEqualToRenderSize(of asset: AVAsset) -> Bool? {
        guard let videoTrack = asset.tracks(withMediaType: .video).first else { return nil }
        if videoTrack.naturalSize == self.renderSize {
            return true
        } else {
            return false
        }
    }
    
    private func setMutableVideoComposition() {
        self.mutableVideoComposition.renderSize = self.renderSize
        self.mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
    }
    
    private func setDuration(of asset: AVAsset) {
        self.currentDuration = asset.duration
    }
    
    private func setPreferredTransform(of asset: AVAsset, mutableVideoTrack: AVMutableCompositionTrack, mutableAudioTrack: AVMutableCompositionTrack) {
        guard let videoTrack = asset.tracks(withMediaType: .video).first else { return }
        guard let audioTrack = asset.tracks(withMediaType: .audio).first else { return }
        mutableVideoTrack.preferredTransform = videoTrack.preferredTransform
        mutableAudioTrack.preferredTransform = audioTrack.preferredTransform
    }
    
    private func insertTimeRange(of asset: AVAsset, mutableVideoTrack: AVMutableCompositionTrack, mutableAudioTrack: AVMutableCompositionTrack) throws {
        do {
            let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            
            guard let videoTrack = asset.tracks(withMediaType: .video).first else {
                throw MovieCombineError.insertTimeRangeError
            }
            guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
                throw MovieCombineError.insertTimeRangeError
            }
            
            try mutableVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: self.currentDuration)
            try mutableAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: self.currentDuration)
        } catch {
            throw MovieCombineError.insertTimeRangeError
        }
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

    private func setLetterboxInstructions(asset: AVAsset, mutableComposition: AVMutableComposition, compositionTrack: AVMutableCompositionTrack) {
        self.mutableVideoCompositionInstruction.timeRange = CMTimeRange(start: .zero, duration: mutableComposition.duration)
        self.mutableVideoComposition.instructions = [mutableVideoCompositionInstruction]
        guard let assetTrack = asset.tracks(withMediaType: .video).first else { return }
        let layerInstruction = setLetterboxVideoCompositionLayerInstruction(asset: asset, compositionTrack: compositionTrack, assetTrack: assetTrack)
        self.mutableVideoCompositionInstruction.layerInstructions = [layerInstruction]
    }
    
    private func setPreferredTransform(of compositionTrack: AVMutableCompositionTrack, to assetTrack: AVAssetTrack) {
        compositionTrack.preferredTransform = assetTrack.preferredTransform
    }
    
    private func orientationFromTransform(_ transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
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
    
    private func export(composition: AVMutableComposition, completion: @escaping (Result<URL?, MovieCombineError>) -> Void) {
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            completion(.failure(.exportError))
            return
        }
        let videoName = UUID().uuidString
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(videoName).appendingPathExtension("mp4")
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
    
}
