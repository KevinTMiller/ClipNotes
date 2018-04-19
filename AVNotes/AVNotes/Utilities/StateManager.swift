//
//  StateManager.swift
//  AVNotes
//
//  Created by Kevin Miller on 3/2/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

class StateManager: NSObject {

    enum CurrentState {
        case error
        case initialize
        case paused
        case playing
        case playingPaused
        case playingStopped
        case prepareToPlay
        case prepareToRecord
        case readyToPlay
        case readyToRecord
        case recording
        case recordingPaused
    }

    static let sharedInstance = StateManager()

    weak var modelDelegate: StateManagerModelDelegate!
    weak var viewDelegate: StateManagerViewDelegate!

    var currentState: CurrentState = .initialize {
        didSet {
            print(currentState)
            performStateChangeAction()
        }
    }

    var needsSave: Bool {
        switch currentState {
        case .recording, .recordingPaused:
            return true
        default:
            return false
        }
    }
    
    var isPlayMode: Bool {
        switch currentState {
        case .playing, .playingPaused, .playingStopped, .readyToPlay, .prepareToPlay:
            return true
        default:
            return false
        }
    }
    
    var isRecordMode: Bool {
        switch currentState {
        case .recording, .recordingPaused, .readyToRecord, .prepareToRecord:
            return true
        default:
            return false
        }
    }
    var canViewFiles: Bool {
        switch currentState {
        case .recording,
             .recordingPaused:
            return false
        default:
            return true
        }
    }
    var canDiscard: Bool {
        switch currentState {
        case .recordingPaused:
            return true
        default:
            return false
        }
    }

    var canAnnotate: Bool {
        switch currentState {
        case .readyToRecord,
             .prepareToRecord,
             .initialize:
            return false
        default:
            return true
        }
    }
    
    var canShare: Bool {
        switch currentState {
        case .playing, .playingPaused, .playingStopped, .readyToPlay, .prepareToPlay:
            return true
        default:
            return false
        }
    }

    var isPlaying: Bool {
        switch currentState {
        case .playing:
            return true
        case .playingPaused:
            return false
        case .playingStopped:
            return false
        default:
            return false
        }
    }
    var isRecording: Bool {
        switch currentState {
        case .recording:
            return true
        case .recordingPaused:
            return false
        default:
            return false
        }
    }

    func performStateChangeAction() {
        switch currentState {
        case .initialize:
            modelDelegate.prepareToRecord(success: {
                viewDelegate.initialSetup()
                currentState = .prepareToRecord
            }, failure: { error in
                viewDelegate.errorAlert(error)
            })
        case .prepareToPlay:
            modelDelegate.prepareToPlay(success: {
                viewDelegate.prepareToPlay()
                currentState = .readyToPlay
            }, failure: { error in
                viewDelegate.errorAlert(error)
            })

        case .prepareToRecord:
            modelDelegate.prepareToRecord(success: {
                viewDelegate.prepareToRecord()
                currentState = .readyToRecord
            }, failure: { error in
                viewDelegate.errorAlert(error)
            })
        case .playingStopped:
            viewDelegate.updateButtons()
        case .playing:
            viewDelegate.playAudio()
        case .playingPaused:
            viewDelegate.updateButtons()
        case .recordingPaused:
            viewDelegate.updateButtons()
        default:
            return
        }
    }

    func toggleRecordingPause(sender: UIButton) {
        switch currentState {
        case .recording:
            modelDelegate.pauseRecording()
            viewDelegate.pauseRecording()
        default:
            return
        }
    }
    
    func toggleRecordingState(sender: UIButton) {
        switch currentState {
        case .recording:
            modelDelegate.pauseRecording()
            viewDelegate.pauseRecording()
        case .readyToRecord:
            modelDelegate.startRecordingAudio()
            viewDelegate.startRecording()
        case .recordingPaused:
            modelDelegate.resumeRecording()
            viewDelegate.resumeRecording()
        default:
            return
        }
    }

    func endRecording() {
        switch currentState {
        case .recording, .recordingPaused:
            modelDelegate.pauseRecording()
            viewDelegate.pauseRecording()
            viewDelegate.stopRecording() // The view delegate will stop the recording as we have to wait for the async alert to get the title. swiftlint:disable:this line_length
        default:
            return
        }
    }

    func togglePlayState(sender: UIButton) {
        switch currentState {
        case .readyToPlay:
            modelDelegate.playAudio()
            viewDelegate.playAudio()
            sender.isSelected = true
        case .playing:
            modelDelegate.pauseAudio()
            sender.isSelected = false
        case .playingPaused:
            modelDelegate.resumeAudio()
            sender.isSelected = true
        case .playingStopped:
            modelDelegate.playAudio()
            viewDelegate.playAudio()
        default:
            sender.isSelected = false
        }
    }

    func allowsAnnotation() -> Bool {
        switch currentState {
        case .recording,
             .playing,
             .playingPaused,
             .recordingPaused,
             .playingStopped,
             .readyToPlay:
            return true
        default:
            return false
        }
    }
}
