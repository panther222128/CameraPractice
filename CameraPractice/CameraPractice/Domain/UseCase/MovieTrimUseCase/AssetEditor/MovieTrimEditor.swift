//
//  AssetEditor.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/17.
//

import AVFoundation
import UIKit

enum MovieTrimEditorError: Error {
    case trimTimeRangeError
    case exportError
}

protocol MovieTrimEditor {
    func trimMovie(of asset: AVAsset, from startTime: Float, to endTime: Float, completion: @escaping (Result<URL?, MovieTrimEditorError>) -> Void)
}

final class DefaultMovieTrimEditor: MovieTrimEditor {

    init() {
    }
    
    func trimMovie(of asset: AVAsset, from startTime: Float, to endTime: Float, completion: @escaping (Result<URL?, MovieTrimEditorError>) -> Void) {
        if (endTime - startTime) <= 0 {
            completion(.failure(.trimTimeRangeError))
        }
        let startTime = CMTime(seconds: Double(startTime), preferredTimescale: 1000)
        let endTime = CMTime(seconds: Double(endTime), preferredTimescale: 1000)
        let timeRange = CMTimeRange(start: startTime, end: endTime)
        
        self.exportTrimmedAsset(from: asset, timeRange: timeRange) { result in
            switch result {
            case .success(let url):
                completion(.success(url))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

}

extension DefaultMovieTrimEditor {

    private func exportTrimmedAsset(from asset: AVAsset, timeRange: CMTimeRange, completion: @escaping (Result<URL?, MovieTrimEditorError>) -> Void) {
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
    
}
