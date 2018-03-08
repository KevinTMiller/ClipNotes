//
//  AudioManager.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/15/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import AudioKit
import AudioKitUI
import AVKit
import UIKit

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

class AudioManager: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    static let sharedInstance = AudioManager()

    enum Constants {
        static let m4aSuffix = "m4a"
        static let lastRecordingKey = "lastRecording"
    }

    // MARK: Public vars

    public var currentState: CurrentState = .fresh {
        didSet {
            print(currentState)
        }
    }
    public var currentMode: CurrentMode = .record {
        didSet {
            print(currentMode)
        }
    }
    public var plot: AKNodeOutputPlot?

    public var isRecording: Bool {
        guard let audioRecorder = audioRecorder else { return false }
        return audioRecorder.isRecording
    }
    
    public var isPlaying: Bool {
        guard let audioPlayer = audioPlayer else { return false }
        return audioPlayer.isPlaying
    }

    public var currentTimeString: String? {
        switch currentMode {
        case .record:
            guard let audioRecorder = audioRecorder else { return nil }
            return String.stringFrom(timeInterval: audioRecorder.currentTime)
        case .play:
            guard let audioPlayer = audioPlayer else { return nil }
            return String.stringFrom(timeInterval: audioPlayer.currentTime)
        }
    }

    public var currentTimeInterval: TimeInterval? {
        switch currentMode {
        case .record:
            guard let audioRecorder = audioRecorder else { return nil }
            return audioRecorder.currentTime
        case .play:
            guard let audioPlayer = audioPlayer else { return nil }
            return audioPlayer.currentTime
        }
    }

    public var currentRecording: AnnotatedRecording? {
        didSet {
            NotificationCenter.default.post(name: .currentRecordingDidChange, object: nil)
            print("Current recording: \(currentRecording!.userTitle)")
        }
    }

    private var blankRecording: AnnotatedRecording?

    // MARK: Private vars
    private let audioSession = AVAudioSession.sharedInstance()
    private let fileManager = RecordingManager.sharedInstance
    private let audioSettings = [
        AVFormatIDKey : Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey : 44_100,
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

    // MARK: AudioKit vars
    public var akMicrophone: AKMicrophone?
    private var tracker: AKFrequencyTracker!
    private var silence: AKBooster!
    private var player: AKAudioPlayer?

    // MARK: AudioKit funcs
    func setUpAKAudio() {
        AKSettings.audioInputEnabled = true
        akMicrophone = AKMicrophone()
        tracker = AKFrequencyTracker(akMicrophone)
        silence = AKBooster(tracker, gain: 0.0)
        AudioKit.output = silence
    }

    func getPlotFromCurrentRecording() -> EZAudioPlot? {
        if let currentRecording = currentRecording {
            let audioFile =
                EZAudioFile(url: getDocumentsDirectory().appendingPathComponent(currentRecording.fileName))
            guard let data = audioFile?.getWaveformData() else { return nil }
            let plot = EZAudioPlot()
            plot.plotType = .buffer
            plot.shouldFill = true
            plot.shouldMirror = true
            plot.color = .white
            plot.updateBuffer(data.buffers[0], withBufferSize: data.bufferSize)
            return plot
        }
        return nil
    }

    // MARK: Public funcs

    /* Starts recording audio by getting a unique filename and the current documents directory
    // then creating a instance of the AVAudioRecord with the current path and settings. */

    func startRecordingAudio() {

        let filename = currentRecording?.fileName
        let audioFilePath = getDocumentsDirectory().appendingPathComponent(filename!)

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilePath, settings: audioSettings)
            audioRecorder?.record()
            currentMode = .record
            currentState = .running
            NotificationCenter.default.post(name: .playRecordDidStart, object: nil)
            print("Recording: \(isRecording)")
        } catch {
            finishRecordingAudio(success: false, path: nil, name: nil)
            currentState = .finishedWithError
        }
    }

    func findIndexOfInsertion(timestamp: Double) -> Int? {
        guard let annotations = currentRecording?.annotations else { return 0 }
        var indexCounter = 0
        while (indexCounter + 1) < annotations.count {
            if annotations[indexCounter].timeStamp < timestamp &&
                annotations[indexCounter + 1].timeStamp >= timestamp {
                return (indexCounter + 1)
            }
            indexCounter += 1
        }
        return nil
    }

    func addAnnotation(title: String, text: String, timestamp: TimeInterval) {
        let timeStampDouble = Double(timestamp)
        let bookmark = Bookmark(title: title, timestamp: timeStampDouble, noteText: text)

        // Find the index of the bookmark with the next smallest time stamp
        // and insert after
        let index = findIndexOfInsertion(timestamp: timestamp)
        if let index = index {
            currentRecording?.annotations?.insert(bookmark, at: index)
        } else {
            currentRecording?.annotations?.append(bookmark)
        }
        fileManager.saveFiles()
        NotificationCenter.default.post(name: .annotationsDidUpdate, object: nil)
    }

    func editBookmark(indexPath: IndexPath, title: String, text: String) {
        currentRecording?.annotations?[indexPath.row].noteText = text
        currentRecording?.annotations?[indexPath.row].title = title
    }

    func stopRecordingAudio() {
        audioRecorder?.stop()
        // Audio recorder's delegate function didFinishRecording is called and finishes
        // the recording
    }

    func togglePause(pause: Bool) {
        if pause {
            audioRecorder?.pause()
            currentState = .paused
        } else {
            audioRecorder?.record()
            currentState = .running
        }
    }

    func switchToRecord() {
        currentRecording = createAnnotatedRecording()
        currentMode = .record
    }

    func switchToPlay(file: AnnotatedRecording) {
        currentRecording = file
        currentMode = .play
    }

    private func setNewRecording() {
        blankRecording = createAnnotatedRecording()
    }

    /* Documents directory path changes frequently.
    Always get a fresh path and then append the filename to create the URL to play */

    func playAudio() {
        audioPlayer?.stop()
        audioPlayer?.prepareToPlay() // Prevents audio player repeating last file
        let audioFilePath = getDocumentsDirectory().appendingPathComponent(currentRecording!.fileName)
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            audioPlayer = try AVAudioPlayer(contentsOf: audioFilePath, fileTypeHint: Constants.m4aSuffix)
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

    func skipTo(timeInterval: TimeInterval) {
        audioPlayer?.currentTime = timeInterval
    }

    func skipFixedTime(time: Double) {
        if let audioPlayer = audioPlayer {
        audioPlayer.currentTime += time
        }
    }

    // TODO: Put this in the init method

    func setUpRecordingSession() {
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setActive(true)
            setUpAKAudio()
            audioSession.requestRecordPermission({ allowed in
                if allowed {
                    print("Audio recording session allowed")
                } else {
                    // TODO: insert error message here to user
                    print("Audio recoding session not allowed")
                }
            })
        } catch {
            // Some error occured
            // TODO: insert error message here to user
            print("Error setting up recording session: \(error)")
        }
        if currentRecording == nil {
            currentRecording = createAnnotatedRecording()
        }
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

        let filename = String.uniqueFileName(suffix: Constants.m4aSuffix)
        let lastRecording = defaults.value(forKey: Constants.lastRecordingKey) as? Int ?? 1
        let userTitle = "New Recording \(lastRecording)"

        return AnnotatedRecording(duration: 0.0, userTitle: userTitle, fileName: filename, mediaType: .audio)
    }

    private func saveRecording(recording: AnnotatedRecording) {
        currentRecording?.duration = getDuration(recording: recording)
        fileManager.recordingArray.insert(currentRecording!, at: 0)
        fileManager.saveFiles()
        let lastRecording = defaults.value(forKey: Constants.lastRecordingKey) as? Int ?? 1
        defaults.set(lastRecording + 1, forKey: Constants.lastRecordingKey)
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
