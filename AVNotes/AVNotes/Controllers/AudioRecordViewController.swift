//
//  AudioRecordViewController.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/5/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import UIKit
import AVKit

let cellIdentifier = "annotationCell"

class AudioRecordViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {


    @IBOutlet weak var waveformView: UIView!
    @IBOutlet weak var tempWaveformLabel: UILabel!
    @IBOutlet weak var stopWatchLabel: UILabel!
    @IBOutlet weak var recordingTitleLabel: UILabel!
    @IBOutlet weak var recordingDateLabel: UILabel!
    @IBOutlet weak var annotationTableView: UITableView!
    
    
    @IBAction func playButtonDidTouch(_ sender: UIButton) {
    }
    @IBAction func recordButtonDidTouch(_ sender: UIButton) {
        startRecording()
    }
    @IBAction func addButtonDidTouch(_ sender: UIButton) {
        addAnnotation()
    }
    
    // MARK: Private Vars
    
    private var audiorecorder = AudioVideoRecorder.sharedInstance
    private var recordingmanager = AVNManager.sharedInstance
    
    // MARK: Model control
    
    private func startRecording() {
        audiorecorder.startRecordingAudio()
    }
    
    private func stopRecording() {
        audiorecorder.stopRecordingAudio()
        
    }
    
    private func addAnnotation() {

        // TODO: Function to get input string from user without interrupting
        // TODO: Add timestamp to arguments of add Annotation method
        audiorecorder.addAnnotation("String from user goes here")
    }
    
    func getCurrentTimeStamp() -> Double {
    
        return 0.0
    }
    
    // MARK: Lifecycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    
    // MARK: Tableview Delegate / DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // TODO: Hook this up to the currentRecording Object on the AVNManager
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: Hook this up to the currentRecording Object on the AVNManager
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        return cell
    }
    
}
