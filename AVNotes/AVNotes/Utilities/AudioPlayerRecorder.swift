//
//  AudioPlayerRecorder.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/15/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import AVKit
import UIKit

//TODO: Refactor class name to AudioManager
enum CurrentState {
    case finishedSuccessfully
    case finishedWithError
    case fresh
    case playing
    case playingPaused
    case playingStopped
    case recording
    case recordingPaused
}

class AudioPlayerRecorder : NSObject , AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    static let sharedInstance = AudioPlayerRecorder()
    
    // MARK: Public vars
    
    public var currentState: CurrentState = .fresh
    
    public var isRecording: Bool {
        guard let audioRecorder = audioRecorder else {return false}
        return audioRecorder.isRecording
    }
    public var isPlaying: Bool {
        guard let audioPlayer = audioPlayer else {return false}
        return audioPlayer.isPlaying
    }
    public var currentTimeString: String? {
        guard let audioRecorder = audioRecorder else {return nil}
        return String.stringFrom(timeInterval: audioRecorder.currentTime)
    }
    public var currentTimeInterval: TimeInterval? {
        guard let audioRecorder = audioRecorder else {return nil}
        return audioRecorder.currentTime
    }
    public var currentRecording: AnnotatedRecording?
    
    // MARK: Private vars
    
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
    
    private var stopwatchFormatter: DateComponentsFormatter! {
        didSet {
            stopwatchFormatter.unitsStyle = .positional
            stopwatchFormatter.allowedUnits = [.hour, .minute, .second, .nanosecond]
            stopwatchFormatter.zeroFormattingBehavior = .pad
            stopwatchFormatter.collapsesLargestUnit = false
            stopwatchFormatter.maximumUnitCount = 4
            stopwatchFormatter.allowsFractionalUnits = true
        }
    }
    // MARK: Public funcs
    
    /* Starts recording audio by getting a unique filename and the current documents directory
    // then creating a instance of the AVAudioRecord with the current path and settings. */
    
    func startRecordingAudio() {
        
        // Should probably store recording number in UserDefaults
        currentRecording = nil
        let filename = String.uniqueFileName(suffix: "m4a")
        let audioFilePath = getDocumentsDirectory().appendingPathComponent(filename)
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilePath, settings: audioSettings)
            audioRecorder?.record()
            currentState = .recording
            print("Recording: \(isRecording)")
        } catch  {
            finishRecordingAudio(success: false, path: nil, name: nil)
            currentState = .finishedWithError
        }
        createAnnotatedRecording(path: audioFilePath, name: filename)
    }
    
    //TODO: create a method to switch out audio sessions
    
    func addAnnotation(title: String, text: String, timestamp: TimeInterval) {
        let timeStampDouble = Double(timestamp)
        let bookmark = AVNAnnotation(title: title, timeStamp: timeStampDouble, noteText: text)
        currentRecording?.annotations?.append(bookmark)
        // TODO: This is probably not great to have this notification here
        // try to find some way to add it to the model?
        NotificationCenter.default.post(name: .annotationsDidUpdate, object: nil)
    }
    
    func stopRecordingAudio() {
        audioRecorder?.stop()
        currentState = .finishedSuccessfully
    }
    
    func togglePause(on: Bool){
        if on {
            audioRecorder?.pause()
            currentState = .recordingPaused
        } else {
            audioRecorder?.record()
            currentState = .recording
        }
    }
    
    /* Documents directory path changes frequently. Always get a fresh path and then append the filename to create the URL to play */
    
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
        currentState = .playing
        print("Playing: \(isPlaying)")
    }
    
    func pauseAudio() {
        audioPlayer?.pause()
        currentState = .playingPaused
    }
    
    func resumeAudio() {
        audioPlayer?.play()
        currentState = .playing
    }
    
    func stopPlayingAudio() {
        audioPlayer?.stop()
        currentState = .playingStopped
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
            currentState = .finishedSuccessfully
        } else {
            currentState = .finishedWithError
        }
        
    }
    // Convenience init method getting long. Consider another init
    private func createAnnotatedRecording(path: URL, name: String) {

        let lastRecording = defaults.value(forKey: "lastRecording") as? Int ?? 1
        let userTitle = "Recording \(lastRecording)"
        defaults.set(lastRecording + 1, forKey: "lastRecording")
        
        currentRecording = AnnotatedRecording(timeStamp: nil,
                                              userTitle: userTitle,
                                              fileName: name,
                                              annotations: [],
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



