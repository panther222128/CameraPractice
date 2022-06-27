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
    private var currentDuration: CMTime
    
    init() {
        self.mutableComposition = AVMutableComposition()
        self.currentDuration = CMTime()
    }
    
    func combineMovies(first: AVAsset, second: AVAsset, completion: @escaping (Result<URL?, MovieCombineError>) -> Void) {
        switch self.insertTimeRange(fisrt: first, second: second) {
        case .success(_):
            completion(.success(nil))
        case .failure(_):
            completion(.failure(.insertTimeRangeError))
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
    
    private func insertTimeRange(fisrt: AVAsset, second: AVAsset) -> Result<AVAsset, MovieCombineError> {
        guard let mutableCompositionVideoTrack = self.mutableComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else { return .failure(.mutableCompositionTrackError) }
        guard let mutableCompositionAudioTrack = self.mutableComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else { return .failure(.mutableCompositionTrackError) }
        
        do {
            let firstTimeRange = CMTimeRange(start: .zero, duration: fisrt.duration)
            
            guard let firstAudioTrack = fisrt.tracks(withMediaType: .audio).first else { return .failure(.assetTrackError) }
            guard let firstVideoTrack = fisrt.tracks(withMediaType: .video).first else { return .failure(.assetTrackError) }
            
            try mutableCompositionAudioTrack.insertTimeRange(firstTimeRange, of: firstAudioTrack, at: self.currentDuration)
            try mutableCompositionVideoTrack.insertTimeRange(firstTimeRange, of: firstVideoTrack, at: self.currentDuration)
            
            mutableCompositionVideoTrack.preferredTransform = firstVideoTrack.preferredTransform
            
            self.currentDuration = fisrt.duration
            
            let secondTimeRange = CMTimeRange(start: .zero, duration: second.duration)
            
            guard let secondAudioTrack = second.tracks(withMediaType: .audio).first else { return .failure(.assetTrackError) }
            guard let secondVideoTrack = second.tracks(withMediaType: .video).first else { return .failure(.assetTrackError) }
            
            try mutableCompositionAudioTrack.insertTimeRange(secondTimeRange, of: secondAudioTrack, at: self.currentDuration)
            try mutableCompositionVideoTrack.insertTimeRange(secondTimeRange, of: secondVideoTrack, at: self.currentDuration)
            
            mutableCompositionVideoTrack.preferredTransform = secondVideoTrack.preferredTransform
            
            self.currentDuration = second.duration
            
            return .success(fisrt)
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
