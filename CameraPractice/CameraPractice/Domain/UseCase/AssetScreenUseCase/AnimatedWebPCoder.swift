//
//  AnimatedWebPCoder.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/08/01.
//

import SDWebImage
import SDWebImageWebPCoder
import AVFoundation

protocol AnimatedWebPCoder {
    func encode(asset: AVAsset) -> UIImage?
}

class DefaultAnimatedWebPCoder: AnimatedWebPCoder {
    
    private var imageGenerator: AVAssetImageGenerator?
    
    init() {
        self.imageGenerator = nil
    }
    
    func encode(asset: AVAsset) -> UIImage? {
        let imageframes = self.makeFrames(from: asset)
        let animatedImage = SDImageCoderHelper.animatedImage(with: imageframes)
        return animatedImage
    }
    
    private func makeFrames(from asset: AVAsset) -> [SDImageFrame] {
        let duration: Float64 = CMTimeGetSeconds(asset.duration)
        self.imageGenerator = AVAssetImageGenerator(asset: asset)
        
        guard let imageGenerator = self.imageGenerator else { return [] }
        imageGenerator.appliesPreferredTrackTransform = true
        
        var frames: [SDImageFrame] = []
        for i: Int in 0..<Int(duration) {
            guard let image = self.extractFrame(from: Float64(i)) else { return [] }
            let imageFrame = SDImageFrame(image: image, duration: .zero)
            frames.append(imageFrame)
        }
        
        return frames
    }
    
    private func extractFrame(from time: Float64) -> UIImage? {
        let time: CMTime = CMTimeMakeWithSeconds(time, preferredTimescale: 600)
        let image: CGImage
        do {
            guard let imageGenerator = self.imageGenerator else { return nil }
            try image = imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: image)
        } catch {
            return nil
        }
    }
    
}
