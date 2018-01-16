//
//  AudioPlayerRecorder.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/15/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import UIKit
import AVKit


class AudioPlayerRecorder : NSObject , AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    static let sharedInstance = AudioPlayerRecorder()
    
    // MARK: Public vars

    public var isRecording: Bool {
        guard let audioRecorder = audioRecorder else {return false}
        return audioRecorder.isRecording
    }
    public var isPlaying: Bool {
        guard let audioPlayer = audioPlayer else {return false}
        return audioPlayer.isPlaying
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
    private var defaults = UserDefaults.standard
    // MARK: Public funcs
    
    /* Starts recording audio by getting a unique filename and the current documents directory
    // then creating a instance of the AVAudioRecord with the current path and settings. */
    
    func startRecordingAudio() {
        
        // Should probably store recording number in UserDefaults
        
        let filename = String.uniqueFileName(suffix: "m4a")
        let audioFilePath = getDocumentsDirectory().appendingPathComponent(filename)

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilePath, settings: audioSettings)
            audioRecorder?.record()
            print("Recording: \(isRecording)")
        } catch  {
            finishRecordingAudio(success: false, path: nil, name: nil)
        }
        createAnnotatedRecording(path: audioFilePath, name: filename)
    }
    
    //TODO: create a method to switch out audio sessions
    
    func addAnnotation(_: String) {
        // TODO: create an annotation in the current recording at the current timestamp
    }
    
    func stopRecordingAudio() {
        audioRecorder?.stop()
    }
    
    func pauseRecordingAudio(){
        audioRecorder?.pause()
    }
    
    /* Documents directory path changes frequently. Always get a fresh path and then append the filename
    // to create the URL to play */
    
    func playAudio(file: AnnotatedRecording) {

        audioPlayer?.stop()
        audioPlayer?.prepareToPlay() // Prevents audio player repeating last file
        let audioFilePath = getDocumentsDirectory().appendingPathComponent(file.fileName)
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            audioPlayer = try AVAudioPlayer(contentsOf: audioFilePath, fileTypeHint: "m4a" )
        } catch let error {
            print(error)
        }
        audioPlayer?.play()
        print("Playing: \(isPlaying)")
    }
    
    
    func stopPlayingAudio() {
        audioPlayer?.stop()
    }
    
    // TODO: Put this in the init method
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

    }
    // Convenience init method getting long. Consider another init
    private func createAnnotatedRecording(path: URL, name: String) {

        let lastRecording = defaults.value(forKey: "lastRecording") as? Int ?? 1
        let userTitle = "Recording \(lastRecording)"
        defaults.set(lastRecording + 1, forKey: "lastRecording")
        
        currentRecording = AnnotatedRecording(timeStamp: nil,
                                              userTitle: userTitle,
                                              fileName: name,
                                              annotations: nil,
                                              mediaType: .audio)
    }
    private func saveRecording(_: AnnotatedRecording) {
        recordingManager.recordingArray.append(currentRecording!)
        
    }
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    // MARK: Delegate funcs
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        finishRecordingAudio(success: flag, path: recorder.url, name: nil)
    }

}



