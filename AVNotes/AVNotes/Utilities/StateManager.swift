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
        case prepareToPlay
        case prepareToRecord
        case readyToPlay
        case readyToRecord
        case recording
        case playing
        case playingPaused
        case playingStopped
        case recordingPaused
        case paused
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
    var isPlayMode: Bool {
        switch currentState {
        case .playing, .playingPaused, .playingStopped, .readyToPlay:
            return true
        default:
            return false
        }
    }
    
    var isRecordMode: Bool {
        switch currentState {
        case .recording:
            return true
        case .recordingPaused:
            return true
        default:
            return false
        }
    }
    var filesButtonEnabled: Bool {
        switch currentState {
        case .recording:
            return false
        default:
            return true
        }
    }

    var plusButtonEnabled: Bool {
        switch currentState {
        case .recording:
            return false
        default:
            return true
        }
    }

    var playButtonSelected: Bool {
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
    var recordButtonSelected: Bool {
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

        default:
            return
        }
    }
    
    func recordButtonPressed(sender: UIButton) {
        switch currentState {
        case .readyToRecord:
            modelDelegate.startRecordingAudio()
            viewDelegate.startRecording()
            sender.isSelected = true
        case .recording:
            modelDelegate.pauseRecording()
            viewDelegate.pauseRecording()
            sender.isSelected = false
        case .recordingPaused:
            modelDelegate.resumeRecording()
            viewDelegate.resumeRecording()
            sender.isSelected = true
        default:
            return
        }
    }

    func doneButtonPressed() {
        switch currentState {
        case .recording, .recordingPaused:
            modelDelegate.stopRecordingAudio()
            viewDelegate.stopRecording()
        default:
            return
        }
    }

    func playButtonPressed(sender: UIButton) {
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
        default:
            sender.isSelected = false
        }
    }

    func shouldShowBookmarkModal() -> Bool {
        switch currentState {
        case .recording, .playing, .playingPaused, .recordingPaused, .playingStopped, .readyToPlay:
            return true
        default:
            return false
        }
    }
}
