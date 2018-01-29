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
    case running
    case paused
    case stopped
}
enum CurrentMode {
    case record
    case play
}

class AudioPlayerRecorder : NSObject , AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    static let sharedInstance = AudioPlayerRecorder()
    let fileSuffix = "m4a"
    let lastRecordingKey = "lastRecording"
    
    // MARK: Public vars
    
    public var currentState: CurrentState = .fresh
    public var currentMode: CurrentMode = .record
    
    // TODO: Check if you need isRecording and isPlaying since you now have
    // the currentState var
    
    // TODO: find a better way to post playRecordDidStart and playRecordDidStop notifications
    
    public var isRecording: Bool {
        guard let audioRecorder = audioRecorder else {return false}
        return audioRecorder.isRecording
    }
    
    public var isPlaying: Bool {
        guard let audioPlayer = audioPlayer else {return false}
        return audioPlayer.isPlaying
    }
    
    public var currentTimeString: String? {
        switch currentMode {
        case .record:
            guard let audioRecorder = audioRecorder else {return nil}
            return String.stringFrom(timeInterval: audioRecorder.currentTime)
        case .play:
            guard let audioPlayer = audioPlayer else {return nil}
            return String.stringFrom(timeInterval: audioPlayer.currentTime)
        }
    }
    
    public var currentTimeInterval: TimeInterval? {
        switch currentMode {
        case .record:
            guard let audioRecorder = audioRecorder else {return nil}
            return audioRecorder.currentTime
        case .play:
            guard let audioPlayer = audioPlayer else {return nil}
            return audioPlayer.currentTime
        }
    }
    
    public var currentRecording: AnnotatedRecording? {
        didSet {
            NotificationCenter.default.post(name: .currentRecordingDidChange, object: nil)
        }
    }
    
    private var blankRecording: AnnotatedRecording?
    
    // MARK: Private vars
    
    private let audioSession = AVAudioSession.sharedInstance()
    private let recordingManager = AVNManager.sharedInstance
    private let audioSettings = [
        AVFormatIDKey : Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey : 44100,
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
        
        if currentRecording == nil {
            currentRecording = createAnnotatedRecording()
        }

        let filename = currentRecording?.fileName
        let audioFilePath = getDocumentsDirectory().appendingPathComponent(filename!)
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilePath, settings: audioSettings)
            audioRecorder?.record()
            currentMode = .record
            currentState = .running
            NotificationCenter.default.post(name: .playRecordDidStart, object: nil)
            print("Recording: \(isRecording)")
        } catch  {
            finishRecordingAudio(success: false, path: nil, name: nil)
            currentState = .finishedWithError
        }
    }
    
    func addAnnotation(title: String, text: String, timestamp: TimeInterval) {
        let timeStampDouble = Double(timestamp)
        let bookmark = AVNAnnotation(title: title, timestamp: timeStampDouble, noteText: text)
        currentRecording?.annotations?.append(bookmark)
        NotificationCenter.default.post(name: .annotationsDidUpdate, object: nil)
    }
    
    func stopRecordingAudio() {
        audioRecorder?.stop()
        // Audio recorder's delegate function didFinishRecording is called and finishes
        // the recording
    }
    
    func togglePause(pause: Bool){
        if pause {
            audioRecorder?.pause()
            currentState = .paused
        } else {
            audioRecorder?.record()
            currentState = .running
        }
    }
    func switchToRecord() {
        currentRecording = blankRecording
    }
    
    private func setNewRecording() {
        blankRecording = createAnnotatedRecording()
    }
    
    /* Documents directory path changes frequently. Always get a fresh path and then append the filename to create the URL to play */
    
    func playAudio() {
        audioPlayer?.stop()
        audioPlayer?.prepareToPlay() // Prevents audio player repeating last file
        let audioFilePath = getDocumentsDirectory().appendingPathComponent(currentRecording!.fileName)
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            audioPlayer = try AVAudioPlayer(contentsOf: audioFilePath, fileTypeHint: fileSuffix )
        } catch let error {
            print(error)
        }
        audioPlayer?.play()
        currentMode = .play
        currentState = .running
        NotificationCenter.default.post(name: .playRecordDidStart, object: nil)
        print("Playing: \(isPlaying)")
    }
    
    func pauseAudio() {
        audioPlayer?.pause()
        currentState = .paused
    }
    
    func resumeAudio() {
        audioPlayer?.play()
        currentState = .running
        NotificationCenter.default.post(name: .playRecordDidStart, object: nil)
    }
    
    func stopPlayingAudio() {
        audioPlayer?.stop()
        currentState = .stopped
    }
    
    func skipTo(timeInterval: TimeInterval){
        audioPlayer?.currentTime = timeInterval
    }
    
    // TODO: Put this in the init method
    // TODO: To continue recording audio when your app transitions to the background
    // (for example, when the screen locks), add the audio value to the UIBackgroundModes
    // key in your information property list file.
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
        setNewRecording()
    }
    
    private func finishRecordingAudio(success: Bool, path: URL?, name: String?) {
        if success {
            saveRecording(recording: currentRecording!)
            currentState = .finishedSuccessfully
        } else {
            currentState = .finishedWithError
        }
        setNewRecording()
    }
 
    // Create an Annotated recording object and set it to the currentRecording property
    // When recording is done, will save to the array in the data manager
    
    private func createAnnotatedRecording() -> AnnotatedRecording {
        
        let filename = String.uniqueFileName(suffix: fileSuffix)
        let lastRecording = defaults.value(forKey: lastRecordingKey) as? Int ?? 1
        let userTitle = "Recording \(lastRecording)"

        return AnnotatedRecording(duration: 0.0, userTitle: userTitle, fileName: filename, mediaType: .audio)
    }
    
    private func saveRecording(recording: AnnotatedRecording) {
        currentRecording?.duration = getDuration(recording: recording)
        recordingManager.recordingArray.append(currentRecording!)
        recordingManager.saveFiles()
        let lastRecording = defaults.value(forKey: lastRecordingKey) as? Int ?? 1
        defaults.set(lastRecording + 1, forKey: lastRecordingKey)
        currentRecording = createAnnotatedRecording()
    }
    
    // .currentTime on AVAudioRecorder returns 0 when stopped.  Must turn the path into
    // an AVasset and then get the duration that way. The other option is to get the current
    // time right before the recording stops, but that could be problematic if the recording
    // stops due to an interruption
    
    private func getDuration(recording: AnnotatedRecording) -> Double {
        let path = getDocumentsDirectory()
        let url = path.appendingPathComponent(recording.fileName)
        let asset = AVURLAsset(url: url)
        let duration = asset.duration
        return duration.seconds
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    // MARK: Delegate funcs
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        finishRecordingAudio(success: flag, path: recorder.url, name: nil)
        NotificationCenter.default.post(name: .playRecordDidStop, object: nil)
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            currentState = .finishedSuccessfully
        } else {
            currentState = .finishedWithError
        }
        NotificationCenter.default.post(name: .audioPlayerDidFinish, object: nil)
        NotificationCenter.default.post(name: .playRecordDidStop, object: nil)
    }

}



