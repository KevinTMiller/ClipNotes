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
enum AudioManagerError: Error {
    case noRecordingPermission
    case errorSettingUpSession
    case errorWithPlayback
    case errorLoadingFile
}

class AudioManager: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    override init() {
        super.init()
        self.stateManager = StateManager.sharedInstance
        stateManager.modelDelegate = self
    }

    static let sharedInstance = AudioManager()

    enum Constants {
        static let m4aSuffix = "m4a"
        static let lastRecordingKey = "lastRecording"
        static let blankTimeString = "00:00"
    }

    // MARK: Public vars
    var stateManager: StateManager!

//    public var currentState: CurrentState = .fresh {
//        didSet {
//            print(currentState)
//        }
//    }
//    public var currentMode: CurrentMode = .record {
//        didSet {
//            print(currentMode)
//        }
//    }

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
        return String.stringFrom(timeInterval: currentTimeInterval)
//        switch stateManager.currentState {
//
//        case .recording:
//            guard let audioRecorder = audioRecorder else { return nil }
//            return String.stringFrom(timeInterval: audioRecorder.currentTime)
//        case .playing:
//            guard let audioPlayer = audioPlayer else { return nil }
//            return String.stringFrom(timeInterval: audioPlayer.currentTime)
//        default:
//            return Constants.blankTimeString
        }

    public var currentTimeInterval: TimeInterval {
        if stateManager.isPlayMode {
            guard let audioPlayer = audioPlayer else { return 0 }
            return audioPlayer.currentTime
        }
        if stateManager.isRecordMode {
            guard let audioRecorder = audioRecorder else { return 0 }
            return audioRecorder.currentTime
        }
        return 0
        //        switch stateManager.currentState {
        //        case .recording:
        //            guard let audioRecorder = audioRecorder else { return 0 }
        //            return audioRecorder.currentTime
        //        case .playing:
        //            guard let audioPlayer = audioPlayer else { return 0 }
        //            return audioPlayer.currentTime
        ////        default:
        //        }
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
    public var akMicrophone: AKMicrophone? {
        didSet {
            print("mic: \(akMicrophone!)")
        }
    }
    private var silence: AKBooster!
    private var player: AKAudioPlayer!
    private var tracker: AKFrequencyTracker!
    var mixer: AKMixer!

    // MARK: AudioKit funcs
    func setUpAKAudio() {
        AKSettings.audioInputEnabled = true
        akMicrophone = AKMicrophone()
//        tracker = AKFrequencyTracker(akMicrophone)
//        silence = AKBooster(tracker, gain: 0.0)
        mixer = AKMixer(akMicrophone)
        AudioKit.output = mixer
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
//        audioPlayer = nil
        let filename = currentRecording?.fileName
        let audioFilePath = getDocumentsDirectory().appendingPathComponent(filename!)
//        setUpAKAudio()
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilePath, settings: audioSettings)
            audioRecorder?.record()
//            currentMode = .record
//            currentState = .running
            stateManager.currentState = .recording
            print("Recording: \(isRecording)")
        } catch {
            print(error)
            finishRecordingAudio(success: false, path: nil, name: nil)
            stateManager.currentState = .error
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
        return 0
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
        if let index =
            fileManager.recordingArray.index(where: {$0.fileName == currentRecording?.fileName}) {
            fileManager.recordingArray[index] = currentRecording!
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

    func pauseRecording() {
       audioRecorder?.pause()
        stateManager.currentState = .recordingPaused
    }

    func resumeRecording() {
        if let success = audioRecorder?.record() {
            if success {
                stateManager.currentState = .recording
            } else {
                stateManager.currentState = .error
            }
        }
    }

//    func togglePause(pause: Bool) {
//        if pause {
//            audioRecorder?.pause()
//            currentState = .paused
//        } else {
//            audioRecorder?.record()
//            currentState = .running
//        }
//    }

    func switchToRecord() {
        setBlankRecording()
        stateManager.currentState = .prepareToRecord
    }

    func switchToPlay(file: AnnotatedRecording) {
        currentRecording = file
        stateManager.currentState = .prepareToPlay
    }

    private func setBlankRecording() {
        currentRecording = createAnnotatedRecording()
    }

    /* Documents directory path changes frequently.
    Always get a fresh path and then append the filename to create the URL to play */
    func prepareToPlay(success: (() -> Void), failure: ((Error) -> Void)) {
        let audioFilePath = getDocumentsDirectory().appendingPathComponent(currentRecording!.fileName)
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            audioPlayer = try AVAudioPlayer(contentsOf: audioFilePath, fileTypeHint: Constants.m4aSuffix)
            audioPlayer?.prepareToPlay()
            success()
        } catch {
            failure(error)
        }
    }

    func prepareToRecord(success: (() -> Void), failure: ((Error) -> Void)) {
        do {
            audioPlayer = nil
            try setUpRecordingSession()
//            currentRecording = createAnnotatedRecording()
//            setUpAKAudio()
            success()
        } catch {
            failure(error)
        }
    }

    func playAudio() {
        audioPlayer?.play()
        stateManager.currentState = .playing
    }

    func pauseAudio() {
        audioPlayer?.pause()
        stateManager.currentState = .playingPaused
    }

    func resumeAudio() {
        audioPlayer?.play()
        stateManager.currentState = .playing
    }

    func stopPlayingAudio() {
        audioPlayer?.stop()
    }

    func skipTo(timeInterval: TimeInterval) {
        audioPlayer?.currentTime = timeInterval
    }

    func skipFixedTime(time: Double) {
        if let audioPlayer = audioPlayer,
        let duration = currentRecording?.duration {
            let newTime = audioPlayer.currentTime + time
            if newTime > duration {
                audioPlayer.currentTime = duration
                pauseAudio()
                return
            }
            if newTime < 0.0 {
                audioPlayer.currentTime = 0.0
                return
            }
        audioPlayer.currentTime += time
        }
    }

    func setUpRecordingSession() throws {
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setActive(true)
//            setUpAKAudio()
            audioSession.requestRecordPermission({ allowed in
                if allowed {
                    print("Audio recording session allowed")
                } else {
                    print("Audio recoding session not allowed")
                }
            })
        } catch {
            throw error
        }
        if currentRecording == nil {
            currentRecording = createAnnotatedRecording()
        }
    }

    private func finishRecordingAudio(success: Bool, path: URL?, name: String?) {
        if success {
            saveRecording(recording: currentRecording!)
            stateManager.currentState = .playingStopped
//            currentState = .finishedSuccessfully
        } else {
//            stateManager.currentState = .error
        }
//        setBlankRecording()
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
//        setBlankRecording()
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
//        NotificationCenter.default.post(name: .playRecordDidStop, object: nil)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            stateManager.currentState = .playingStopped
        } else {
            stateManager.currentState = .error
        }
    }
}
extension AudioManager: StateManagerModelDelegate {

}
