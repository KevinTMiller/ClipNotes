//
//  AudioVideoRecorder.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/15/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import UIKit
import AVKit


class AudioVideoRecorder : NSObject , AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    static let sharedInstance = AudioVideoRecorder()
    
    // MARK: Public vars

    public var isRecording: Bool {
        guard let audioRecorder = audioRecorder else {return false}
        return audioRecorder.isRecording
    }

    
    // MARK: Private vars
    
    private var currentRecording: AnnotatedRecording?
    private let audioSession = AVAudioSession.sharedInstance()
    private let recordingManager = AVNManager.sharedInstance
    private let audioSettings = [
        AVFormatIDKey : Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey : 12000,
        AVNumberOfChannelsKey : 1,
        AVEncoderAudioQualityKey : AVAudioQuality.high.rawValue
    ]
    private var audioRecorder: AVAudioRecorder? {
        didSet {
            audioRecorder?.delegate = self
        }
    }
    private var audioPlayer: AVAudioPlayer? {
        didSet {
            audioPlayer?.delegate = self
            audioPlayer?.setVolume(1.0, fadeDuration: 0.0)
        }
    }
    
    // MARK: Public funcs
    
    func startRecordingAudio() {
        
        // Should probably store recording number in UserDefaults
        
        let filename = String.uniqueFileName(suffix: "m4a")
        let audioFilePath = getDocumentsDirectory().appendingPathComponent(filename)

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilePath, settings: audioSettings)
            audioRecorder?.record()
            print("Recording: \(audioRecorder!.isRecording)")
        } catch  {
            finishRecordingAudio(success: false, path: nil, name: nil)
        }
        createAnnotatedRecording(path: audioFilePath, name: filename)
    }
    
    func addAnnotation(_: String) {
        
    }
    
    func stopRecordingAudio() {
        audioRecorder?.stop()
        audioRecorder = nil
    }
    
    func pauseRecordingAudio(){
        audioRecorder?.pause()
    }
    
    func startRecordingVideo() {
        
    }
    
    func stopRecordingVideo() {
        
    }
    
    func playAudio(file: AnnotatedRecording) {
        try? audioSession.setCategory(AVAudioSessionCategoryPlayback)
        audioPlayer = try? AVAudioPlayer(contentsOf: file.recordingPath, fileTypeHint: "m4a" )
        audioPlayer?.play()
    }
    
    func playVideo() {
        
    }
    
    func stopPlayingAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    func stopPlayingVideo() {
        
    }
    // MARK: Private funcs
    
    private func autoGenerateFileName() -> String {
        
        let filename = ""
        return filename
    }
    
    private func setUpAudioRecorder() {
        
    }
    func setUpRecordingSession() {
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setActive(true)
            audioSession.requestRecordPermission({ (allowed) in
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
        audioRecorder?.stop()
        
        if success {
            saveRecording(currentRecording!)
            currentRecording = nil
        }
        // TODO: add fail case where recording is interruped after starting

        print("Recording: \(audioRecorder?.isRecording)")

    }
    private func finishRecordingVideo() {
        
    }
    // Convenience init method getting long. Consider another init
    private func createAnnotatedRecording(path: URL, name: String) {
        currentRecording = AnnotatedRecording(timeStamp: nil,
                                                               title: name,
                                                               recordingPath: path,
                                                               annotations: nil)
        
    }
    private func saveRecording(_: AnnotatedRecording) {
        recordingManager.recordingArray.append(currentRecording!)
        
    }
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    // MARK: delegate funcs
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        finishRecordingAudio(success: flag, path: recorder.url, name: nil)
    }
}
