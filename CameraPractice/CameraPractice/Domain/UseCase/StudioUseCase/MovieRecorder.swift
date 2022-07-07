//
//  AssetWriter.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/07/05.
//

import AVFoundation
import UIKit

protocol MovieRecordable {
    func startRecording(videoTransform: CGAffineTransform)
    func stopRecording(completion: @escaping (URL) -> Void)
    func recordVideo(sampleBuffer: CMSampleBuffer)
    func recordAudio(sampleBuffer: CMSampleBuffer)
}

final class DefaultMovieRecorder: MovieRecordable {
    
    private var assetWriter: AVAssetWriter?
    private var assetWriterVideoInput: AVAssetWriterInput?
    private var assetWriterAudioInput: AVAssetWriterInput?
    
    init() {
        self.assetWriter = nil
        self.assetWriterVideoInput = nil
        self.assetWriterAudioInput = nil
    }
    
    func startRecording(videoTransform: CGAffineTransform) {
        let outputFileName = NSUUID().uuidString
        let outputFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outputFileName).appendingPathExtension("MOV")
        guard let assetWriter = try? AVAssetWriter(url: outputFileURL, fileType: .mov) else {
            return
        }
        let assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
        assetWriterAudioInput.expectsMediaDataInRealTime = true
        assetWriter.add(assetWriterAudioInput)
        
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: nil)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        assetWriterVideoInput.transform = videoTransform
        assetWriter.add(assetWriterVideoInput)
        
        self.assetWriter = assetWriter
        self.assetWriterAudioInput = assetWriterAudioInput
        self.assetWriterVideoInput = assetWriterVideoInput
    }
    
    func stopRecording(completion: @escaping (URL) -> Void) {
        guard let assetWriter = assetWriter else { return }
        
        self.assetWriter = nil
        
        assetWriter.finishWriting {
            completion(assetWriter.outputURL)
        }
    }
    
    func recordVideo(sampleBuffer: CMSampleBuffer) {
        guard let assetWriter = assetWriter else { return }
        
        if assetWriter.status == .unknown {
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        } else if assetWriter.status == .writing {
            if let input = assetWriterVideoInput,
                input.isReadyForMoreMediaData {
                input.append(sampleBuffer)
            }
        }
    }
    
    func recordAudio(sampleBuffer: CMSampleBuffer) {
        guard let assetWriter = assetWriter, assetWriter.status == .writing, let input = assetWriterAudioInput, input.isReadyForMoreMediaData else { return }
        input.append(sampleBuffer)
    }
    
}
