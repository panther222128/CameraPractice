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
    case mutableCompositionError
    case makeLetterboxError
}

protocol MovieCombineEditor {
    func combineMovies(assets: [AVAsset], completion: @escaping (Result<URL?, MovieCombineError>) -> Void)
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
    
    func combineMovies(assets: [AVAsset], completion: @escaping (Result<URL?, MovieCombineError>) -> Void) {
        let mergedMutableComposition = AVMutableComposition()
        
        let mergedVideoMutableCompositionTrack = mergedMutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let mergedAudioMutableCompositionTrack = mergedMutableComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        var count = 0
        var insertTime = CMTime.zero
        var instructions = [AVMutableVideoCompositionInstruction]()
        
        for asset in assets {
            guard let videoTrack = asset.tracks(withMediaType: .video).first else { return }
            guard let audioTrack = asset.tracks(withMediaType: .audio).first else { return }
            
            do {
                guard let mergedVideoMutableCompositionTrack = mergedVideoMutableCompositionTrack else { return }
                guard let mergedAudioMutableCompositionTrack = mergedAudioMutableCompositionTrack else { return }
                
                try mergedVideoMutableCompositionTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: videoTrack, at: insertTime)
                try mergedAudioMutableCompositionTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: asset.duration), of: audioTrack, at: insertTime)
                
                let videoCompositionInstruction = AVMutableVideoCompositionInstruction()
                let videoLayerInstruction = self.videoCompositionInstruction(asset: asset, count: count)
                
                videoCompositionInstruction.timeRange = CMTimeRangeMake(start: insertTime, duration: asset.duration)
                videoCompositionInstruction.layerInstructions = [videoLayerInstruction]
                
                instructions.append(videoCompositionInstruction)
                
                insertTime = CMTimeAdd(insertTime, asset.duration)
                count += 1
            } catch {
                
            }
        }
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = instructions
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderSize = self.renderSize
        
        guard let exportSession = AVAssetExportSession(asset: mergedMutableComposition, presetName: AVAssetExportPresetHEVCHighestQuality) else { return }
        let videoName = UUID().uuidString
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(videoName).appendingPathExtension("mov")
        exportSession.outputFileType = .mov
        exportSession.outputURL = exportURL
        exportSession.videoComposition = videoComposition
        
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
    
    private func videoCompositionInstruction(asset: AVAsset, count: Int) -> AVMutableVideoCompositionLayerInstruction {
        guard let assetTrack = asset.tracks(withMediaType: .video).first else { return AVMutableVideoCompositionLayerInstruction() }

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
        
        if count == 0 {
            layerInstruction.setOpacity(0.0, at: asset.duration)
        }
        
        return layerInstruction
    }
    
    func combineMovies(first: AVAsset, second: AVAsset, completion: @escaping (Result<URL?, MovieCombineError>) -> Void) {
        var firstComposition = AVMutableComposition()
        var secondComposition = AVMutableComposition()

        guard let firstVideoTrack = first.tracks(withMediaType: .video).first else { return }
        guard let secondVideoTrack = second.tracks(withMediaType: .video).first else { return }

        if firstVideoTrack.naturalSize == self.renderSize && secondVideoTrack.naturalSize == self.renderSize {

        } else {
            if let firstMutableVideoTrack = first.tracks(withMediaType: .video).first {
                if firstMutableVideoTrack.naturalSize != self.renderSize {
                    self.makeLetterbox(to: first) { result in
                        switch result {
                        case .success(let asset):

                            completion(.success(nil))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
            }

            if let secondMutableVideoTrack = second.tracks(withMediaType: .video).first {
                if secondMutableVideoTrack.naturalSize != self.renderSize {
                    self.makeLetterbox(to: second) { result in
                        switch result {
                        case .success(let asset):
                            completion(.success(nil))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
            }
        }
        
        guard let mutableVideoTrack = self.mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(.failure(.insertTimeRangeError))
            return
        }
        guard let mutableAudioTrack = self.mutableComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(.failure(.insertTimeRangeError))
            return
        }
        
        self.setMutableVideoComposition()
        
        guard let firstMutableVideoTrack = firstComposition.tracks(withMediaType: .video).first else { return }
        guard let firstMutableAudioTrack = firstComposition.tracks(withMediaType: .audio).first else { return }
        guard let secondMutableVideoTrack = secondComposition.tracks(withMediaType: .video).first else { return }
        guard let secondMutableAudioTrack = secondComposition.tracks(withMediaType: .audio).first else { return }
        
        do {
            try mutableVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: first.duration), of: firstMutableVideoTrack, at: self.currentDuration)
            try mutableAudioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: first.duration), of: firstMutableAudioTrack, at: self.currentDuration)
        } catch {
            completion(.failure(.insertTimeRangeError))
            return
        }
        self.setDuration(of: first)
        do {
            try mutableVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: second.duration), of: secondMutableVideoTrack, at: self.currentDuration)
            try mutableAudioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: second.duration), of: secondMutableAudioTrack, at: self.currentDuration)
        } catch {
            completion(.failure(.insertTimeRangeError))
            return
        }
        self.setDuration(of: second)
        self.setPreferredTransform(of: first, mutableVideoTrack: mutableVideoTrack, mutableAudioTrack: mutableVideoTrack)
        self.setPreferredTransform(of: second, mutableVideoTrack: mutableVideoTrack, mutableAudioTrack: mutableVideoTrack)
        
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
    
    private func makeLetterbox(to asset: AVAsset, completion: @escaping (Result<AVAsset, MovieCombineError>) -> Void) {
        guard let mutableVideoTrack = mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(.failure(.mutableCompositionTrackError))
            return
        }
        guard let mutableAudioTrack = mutableComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(.failure(.mutableCompositionTrackError))
            return
        }
        do {
            try self.insertTimeRange(of: asset, mutableVideoTrack: mutableVideoTrack, mutableAudioTrack: mutableAudioTrack)
        } catch {
            completion(.failure(.insertTimeRangeError))
            return
        }
        
        let videoLayer: CALayer = CALayer()
        self.setVideoLayer(to: videoLayer)
        let outputLayer: CALayer = CALayer()
        self.setLetterboxOutputLayer(outputLayer: outputLayer, videoLayer: videoLayer)
        self.setMutableVideoComposition(videoLayer: videoLayer, outputLayer: outputLayer)
        self.setLetterboxInstructions(asset: asset, mutableComposition: mutableComposition, compositionTrack: mutableVideoTrack)
        completion(.success(asset))
    }
    
    private func setVideoLayer(to layer: CALayer) {
        layer.frame = CGRect(origin: .zero, size: self.renderSize)
    }
    
    private func setMutableVideoComposition(videoLayer: CALayer, outputLayer: CALayer) {
        self.mutableVideoComposition.renderSize = self.renderSize
        self.mutableVideoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        self.mutableVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: outputLayer)
    }
    
    private func setLetterboxOutputLayer(outputLayer: CALayer, videoLayer: CALayer) {
        outputLayer.frame = CGRect(origin: .zero, size: self.renderSize)
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
        mutableVideoTrack.preferredTransform = videoTrack.fixedPreferredTransform
        mutableAudioTrack.preferredTransform = audioTrack.fixedPreferredTransform
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
