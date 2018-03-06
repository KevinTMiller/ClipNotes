//
//  StateManagerDelegates.swift
//  AVNotes
//
//  Created by Kevin Miller on 3/2/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import Foundation
import UIKit

protocol StateManagerViewDelegate: AnyObject {
    func errorAlert(_ error: Error)
    func stopRecording()
    func playAudio()
    func prepareToPlay()
    func prepareToRecord()
    func startRecording()
    func pauseRecording()
    func resumeRecording()
    func initialSetup()
    func updateButtons()
}

protocol StateManagerModelDelegate: AnyObject {

// Record

// Play

    // Setup

    func stopRecordingAudio()
    func pauseAudio()
    func pauseRecording()
    func playAudio()
    func prepareToPlay(success: (() -> Void), failure: ((Error) -> Void))
    func prepareToRecord(success: (() -> Void), failure: ((Error) -> Void))
    func startRecordingAudio()
    func resumeRecording()
    func resumeAudio()
}
