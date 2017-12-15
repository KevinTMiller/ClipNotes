//
//  AudioVideoRecorder.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/15/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import UIKit
import AVKit

class AudioVideoRecorder : NSObject , AVAudioRecorderDelegate {
    
    static let sharedInstance = AudioVideoRecorder()
    
    // MARK: Public vars
    
    var isRecording: Bool {
        return audioRecorder.isRecording
    }
   
    // MARK: Private vars
    
    private var currentRecording: AnnotatedRecording?
    private let recordingSession = AVAudioSession.sharedInstance()
    private let recordingManager = AVNManager.sharedInstance
    private let audioSettings = [
        AVFormatIDKey : Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey : 12000,
        AVNumberOfChannelsKey : 1,
        AVEncoderAudioQualityKey : AVAudioQuality.high.rawValue
    ]
    private var audioRecorder = AVAudioRecorder() {
        didSet {
            setUpRecordingSession()
            audioRecorder.delegate = self
        }
    }
    
    // MARK: Public funcs
    
    func startRecordingAudio() {
        
        // Should probably store recording number in UserDefaults
        
        let filename = "NewRecording.m4a"
        let audioFilePath = getDocumentsDirectory().appendingPathComponent(filename)

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilePath, settings: audioSettings)
            audioRecorder.record()
            print("Recording: \(audioRecorder.isRecording)")
        } catch  {
            finishRecordingAudio(success: false, path: nil, name: nil)
        }
        createAnnotatedRecording(path: audioFilePath, name: filename)
    }
    func addAnnotation(_: String) {
        
    }

    
    func stopRecordingAudio() {
        audioRecorder.stop()
    }
    func pauseRecordingAudio(){
        audioRecorder.pause()
    }
    func startRecordingVideo() {
        
    }
    func stopRecordingVideo() {
        
    }

    
    private func setUpAudioRecorder() {
        
    }
    private func setUpRecordingSession() {
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission({ (allowed) in
                if allowed {
                    print("Audio recording session allowed")
                } else {
                    // TODO: insert error message here to user
                    print("Audio recoding session not allowed")
                }
            })
        } catch  {
            // Some error occured
            // TODO: insert error message here to user
            print("Error setting up recording session: \(error)")
        }
        
    }
    
    private func finishRecordingAudio(success: Bool, path: URL?, name: String?) {
        audioRecorder.stop()
        
        if success {
            AVNManager.sharedInstance.recordingArray.append(currentRecording!)
            currentRecording = nil
        }
        // TODO: add fail case where recording is interruped after starting
        

        print("Recording: \(audioRecorder.isRecording)")

    }
    private func finishRecordingVideo() {
        
    }
    private func createAnnotatedRecording(path: URL, name: String) {
        recordingManager.currentRecording = AnnotatedRecording(title: name,
                                              recordingPath: path,
                                              annotations: nil)
    }
    private func saveRecording(_: AnnotatedRecording) {
        
    }
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
