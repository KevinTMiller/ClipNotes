//
//  WaveFormDrawingImageView.swift
//  AVNotes
//
//  Created by Kevin Miller on 1/17/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit
import AVFoundation
import Accelerate

struct ReadFile {
    var arrayFloatValues: [Float] = []
    var points: [CGPoint] = []
}
class WaveFormDrawingImageView: UIImageView {

    var audioManager = AudioPlayerRecorder.sharedInstance
    var asset: AVAsset?
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let currentRecording = audioManager.currentRecording {
            asset = AVAsset(url: getDocumentsDirectory().appendingPathComponent(currentRecording.fileName))
        }
    }
    override func draw(_ rect: CGRect) {
        
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
