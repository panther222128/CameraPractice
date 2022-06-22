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
    
    private var mutableComposition: AVMutableComposition
    private var mutableCompositionTrack: AVMutableCompositionTrack?
    private var mutableVideoCompositionInstruction: AVMutableVideoCompositionInstruction
    private var currentDuration: CMTime
    
    init() {
        self.mutableComposition = AVMutableComposition()
        self.mutableCompositionTrack = nil
        self.mutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        self.currentDuration = CMTime()
    }
    
    func combineMovies(first: AVAsset, second: AVAsset, completion: @escaping (Result<URL?, MovieCombineError>) -> Void) {
        switch self.insertTimeRange(of: first) {
        case .success(_):
            completion(.success(nil))
        case .failure(_):
            completion(.failure(.insertTimeRangeError))
        }
        
        switch self.insertTimeRange(of: second) {
        case .success(_):
            completion(.success(nil))
        case .failure(let error):
            completion(.failure(error))
        }
        
        self.export(composition: self.mutableComposition) { result in
            switch result {
            case .success(let url):
                completion(.success(url))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}

extension DefaultMovieCombineEditor {
    
    private func insertTimeRange(of asset: AVAsset) -> Result<AVAsset, MovieCombineError> {
        guard let mutableCompositionVideoTrack = self.mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { return .failure(.mutableCompositionTrackError) }
        guard let mutableCompositionAudioTrack = self.mutableComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { return .failure(.mutableCompositionTrackError)}
        
        do {
            self.currentDuration = asset.duration
            
            let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            
            guard let audioTrack = asset.tracks(withMediaType: .audio).first else { return .failure(.assetTrackError) }
            guard let videoTrack = asset.tracks(withMediaType: .video).first else { return .failure(.assetTrackError) }
            
            try mutableCompositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: self.currentDuration)
            try mutableCompositionVideoTrack.insertTimeRange(timeRange, of: videoTrack, at: self.currentDuration)
            
            mutableCompositionVideoTrack.preferredTransform = videoTrack.preferredTransform
            
            return .success(asset)
        } catch {
            return .failure(.insertTimeRangeError)
        }
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
