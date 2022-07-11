//
//  CameraUseCase.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/05/27.
//

import AVFoundation
import Photos
import UIKit

protocol StudioUseCase {
    func checkDeviceAccessAuthorizationStatus(completion: @escaping (Bool) -> Void)
    func checkPhotoAlbumAccessAuthorizationStatus(completion: @escaping (Bool) -> Void)
    func capturePhoto(photoSettings: AVCapturePhotoSettings, photoOutput: AVCapturePhotoOutput)

    func recordVideo(sampleBuffer: CMSampleBuffer)
    func recordAudio(sampleBuffer: CMSampleBuffer)
    func startRecording(videoTransform: CGAffineTransform, videoDataOutput: AVCaptureVideoDataOutput, audioDataOutput: AVCaptureAudioDataOutput)
    func stopRecording(completion: @escaping (URL) -> Void)
    func saveMovie(outputUrl: URL)
}

final class DefaultStudioUseCase: StudioUseCase {
    
    private let cameraRepository: StudioRepository
    private let authorizationManager: AuthorizationManager
    private var movieRecorder: MovieRecordable
    private var inProgressPhotoCaptureDelegates: [Int64: PhotoCaptureProcessor]
    private var outputUrl: URL?
    
    init(cameraRepository: StudioRepository, authorizationManager: AuthorizationManager, inProgressPhotoCaptureDelegates: [Int64: PhotoCaptureProcessor]) {
        self.cameraRepository = cameraRepository
        self.authorizationManager = authorizationManager
        self.inProgressPhotoCaptureDelegates = inProgressPhotoCaptureDelegates
        self.movieRecorder = DefaultMovieRecorder()
    }
    
    func checkDeviceAccessAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        self.authorizationManager.checkDeviceAuthorization { isAuthorized in
            switch isAuthorized {
            case true:
                completion(true)
            case false:
                self.requestForDeviceAccess { isAuthorized in
                    switch isAuthorized {
                    case true:
                        completion(true)
                    case false:
                        completion(false)
                    }
                }
            }
        }
    }
    
    func checkPhotoAlbumAccessAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        self.authorizationManager.checkPhotoAlbumAuthorization { isAuthorized in
            switch isAuthorized {
            case true:
                completion(true)
            case false:
                self.requestForPhotoAlbumAccess { isAuthorized in
                    switch isAuthorized {
                    case true:
                        completion(true)
                    case false:
                        completion(false)
                    }
                }
            }
        }
    }
    
    func capturePhoto(photoSettings: AVCapturePhotoSettings, photoOutput: AVCapturePhotoOutput) {
        let photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings) { photoCaptureProcessor in
            DispatchQueue.main.async {
                self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
            }
        }
        
        self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
        
        photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
    }
    
    func recordVideo(sampleBuffer: CMSampleBuffer) {
        self.movieRecorder.recordVideo(sampleBuffer: sampleBuffer)
    }
    
    func recordAudio(sampleBuffer: CMSampleBuffer) {
        self.movieRecorder.recordAudio(sampleBuffer: sampleBuffer)
    }
    
    func startRecording(videoTransform: CGAffineTransform, videoDataOutput: AVCaptureVideoDataOutput, audioDataOutput: AVCaptureAudioDataOutput) {
        self.movieRecorder.startRecording(videoTransform: videoTransform, videoDataOutput: videoDataOutput, audioDataOutput: audioDataOutput)
    }
    
    func stopRecording(completion: @escaping (URL) -> Void) {
        self.movieRecorder.stopRecording(completion: completion)
    }
    
    func saveMovie(outputUrl: URL) {
        self.cameraRepository.saveMovieToPhotoLibrary(outputUrl)
    }

}

extension DefaultStudioUseCase {
    
    private func requestForDeviceAccess(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { isAuthorized in
            if !isAuthorized {
                completion(false)
            } else {
                completion(true)
            }
        })
    }
    
    private func requestForPhotoAlbumAccess(completion: @escaping (Bool) -> Void) {
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { authorizationStatus in
                switch authorizationStatus {
                case .authorized:
                    completion(true)
                default:
                    completion(false)
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    private func generateUrl() -> URL? {
        let directory = NSTemporaryDirectory() as NSString
        
        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }
        
        return nil
    }
    
}
