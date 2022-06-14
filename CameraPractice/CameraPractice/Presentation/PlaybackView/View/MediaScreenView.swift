//
//  MediaScreenView.swift
//  CameraPractice
//
//  Created by Jun Ho JANG on 2022/06/14.
//

import UIKit
import AVFoundation

class MediaScreenView: UIView {

    var mediaPlayer: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
}
