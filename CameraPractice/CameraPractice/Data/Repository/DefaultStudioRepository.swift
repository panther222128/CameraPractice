//
//  DefaultCameraRepository.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import Photos

final class DefaultStudioRepository: StudioRepository {
    
    func saveMovieToPhotoLibrary(_ movieURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                // Save the movie file to the photo library and clean up.
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = true
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .video, fileURL: movieURL, options: options)
                }, completionHandler: { success, error in
                    if FileManager.default.fileExists(atPath: movieURL.path) {
                        do {
                            try FileManager.default.removeItem(atPath: movieURL.path)
                        } catch {
                            print("Could not remove file at url: \(movieURL)")
                        }
                    }
                })
            }
        }
    }
    
}
