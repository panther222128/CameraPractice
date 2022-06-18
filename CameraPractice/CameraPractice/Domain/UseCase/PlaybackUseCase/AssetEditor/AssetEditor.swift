//
//  AssetEditor.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/17.
//

import AVFoundation
import UIKit

enum AssetEditorError: Error {
    case addMutableTrackError
    case assetTrackError
    case insertTimeRangeError
    case exportError
}

protocol AssetEditor {
    func addOverlay(to asset: AVAsset, completion: @escaping (Result<URL?, AssetEditorError>) -> Void)
}

final class DefaultAssetEditor: AssetEditor {
    
    func addOverlay(to asset: AVAsset, completion: @escaping (Result<URL?, AssetEditorError>) -> Void) {
        let composition = AVMutableComposition()
        
        guard let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(.failure(.addMutableTrackError))
            return
        }
        guard let assetTrack = asset.tracks(withMediaType: .video).first else {
            completion(.failure(.assetTrackError))
            return
        }
        
        do {
            let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
            if let audioAssetTrack = asset.tracks(withMediaType: .audio).first, let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                try compositionAudioTrack.insertTimeRange(timeRange, of: audioAssetTrack, at: .zero)
            }
        } catch {
            completion(.failure(.insertTimeRangeError))
            return
        }
        
        compositionTrack.preferredTransform = assetTrack.preferredTransform
        let videoInfo = orientation(from: assetTrack.preferredTransform)
        let videoSize: CGSize
        if videoInfo.isPortrait {
            videoSize = CGSize(width: assetTrack.naturalSize.height, height: assetTrack.naturalSize.width)
        } else {
            videoSize = assetTrack.naturalSize
        }
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)
        
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(origin: .zero, size: videoSize)
        
        addImage(to: overlayLayer, videoSize: videoSize)
        
        let outputLayer = CALayer()
        outputLayer.frame = CGRect(origin: .zero, size: videoSize)
        outputLayer.addSublayer(videoLayer)
        outputLayer.addSublayer(overlayLayer)
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: outputLayer)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
        videoComposition.instructions = [instruction]
        let layerInstruction = compositionLayerInstruction(for: compositionTrack, assetTrack: assetTrack)
        instruction.layerInstructions = [layerInstruction]
        
        self.export(composition: composition, videoComposition: videoComposition) { result in
            switch result {
            case .success(let url):
                completion(.success(url))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}

extension DefaultAssetEditor {
    
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
