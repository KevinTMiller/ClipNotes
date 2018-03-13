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
    func initialSetup()
    func pauseRecording()
    func playAudio()
    func prepareToPlay()
    func prepareToRecord()
    func resumeRecording()
    func stopRecording()
    func startRecording()
    func updateButtons()
}

protocol StateManagerModelDelegate: AnyObject {
    func emergencySave()
    func pauseAudio()
    func pauseRecording()
    func playAudio()
    func prepareToPlay(success: (() -> Void), failure: ((Error) -> Void))
    func prepareToRecord(success: (() -> Void), failure: ((Error) -> Void))
    func resumeAudio()
    func resumeRecording()
    func startRecordingAudio()
    func stopRecordingAudio()
}
