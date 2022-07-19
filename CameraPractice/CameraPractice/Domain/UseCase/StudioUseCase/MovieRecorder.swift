//
//  AssetWriter.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/07/05.
//

import AVFoundation
import UIKit

protocol MovieRecordable {
    func startRecording(videoTransform: CGAffineTransform, videoDataOutput: AVCaptureVideoDataOutput, audioDataOutput: AVCaptureAudioDataOutput)
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
    
    func startRecording(videoTransform: CGAffineTransform, videoDataOutput: AVCaptureVideoDataOutput, audioDataOutput: AVCaptureAudioDataOutput) {
        let outputFileName = NSUUID().uuidString
        let outputFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outputFileName).appendingPathExtension("MOV")
        guard let assetWriter = try? AVAssetWriter(url: outputFileURL, fileType: .mov) else { return }
        
        let assetWriterVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoDataOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mov))
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        assetWriterVideoInput.transform = videoTransform
        
        if assetWriter.canAdd(assetWriterVideoInput) {
            assetWriter.add(assetWriterVideoInput)
        }
        
        let assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioDataOutput.recommendedAudioSettingsForAssetWriter(writingTo: .mov))
        assetWriterAudioInput.expectsMediaDataInRealTime = true
        
        if assetWriter.canAdd(assetWriterAudioInput) {
            assetWriter.add(assetWriterAudioInput)
        }
        self.assetWriter = assetWriter
        self.assetWriterVideoInput = assetWriterVideoInput
        self.assetWriterAudioInput = assetWriterAudioInput
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
            if let input = self.assetWriterVideoInput,
                input.isReadyForMoreMediaData {
                input.append(sampleBuffer)
            }
        }
    }
    
    func recordAudio(sampleBuffer: CMSampleBuffer) {
        guard let assetWriter = assetWriter, assetWriter.status == .writing, let input = self.assetWriterAudioInput, input.isReadyForMoreMediaData else { return }
        input.append(sampleBuffer)
    }
    
}
