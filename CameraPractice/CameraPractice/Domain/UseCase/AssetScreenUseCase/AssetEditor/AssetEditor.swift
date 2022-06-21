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
}

protocol AssetEditor {
    func addImageOverlay(of image: UIImage?, to asset: AVAsset, completion: @escaping (Result<URL?, AssetEditorError>) -> Void)
}

final class DefaultAssetEditor: AssetEditor {
    
    private var mutableComposition: AVMutableComposition
    private var assetTrack: AVAssetTrack?
    private var mutableCompositionTrack: AVMutableCompositionTrack?
    private var videoLayer: CALayer
    private var overlayLayer: CALayer
    private var outputLayer: CALayer
    private var mutableVideoComposition: AVMutableVideoComposition
    private var mutableVideoCompositionInstruction: AVMutableVideoCompositionInstruction
    
    init() {
        self.mutableComposition = AVMutableComposition()
        self.assetTrack = nil
        self.mutableCompositionTrack = nil
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

}

extension DefaultAssetEditor {

    private func addMutableTrack() {
        self.mutableCompositionTrack = self.mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
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
        self.videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: size)
    }
    
    private func setOverlayLayer(size: CGSize) {
        self.overlayLayer = CALayer()
        overlayLayer.frame = CGRect(origin: .zero, size: size)
    }
    
    private func setOutputLayer(videoLayer: CALayer, overlayLayer: CALayer, size: CGSize) {
        self.outputLayer = CALayer()
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
        mutableVideoCompositionInstruction.layerInstructions = [layerInstruction]
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
    
    private func addImage(of image: UIImage?, to layer: CALayer, videoSize: CGSize) {
        guard let image = image else { return }
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
