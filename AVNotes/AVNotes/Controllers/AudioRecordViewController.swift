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
        stopRecording()
    }
    @IBAction func recordButtonDidTouch(_ sender: UIButton) {
        startRecording()
    }
    @IBAction func addButtonDidTouch(_ sender: UIButton) {
        addAnnotation()
    }
    
    // MARK: Private Vars
    
    private var mediaManager = AudioVideoRecorder.sharedInstance
    private var fileManager = AVNManager.sharedInstance
    private var isRecording: Bool {
        return mediaManager.isRecording
    }
    
    // MARK: Model control
    
    private func startRecording() {
        mediaManager.startRecordingAudio()
    }
    
    private func stopRecording() {
        mediaManager.stopRecordingAudio()
        
    }
    
    private func addAnnotation() {

        // TODO: Function to get input string from user without interrupting
        // TODO: Add timestamp to arguments of add Annotation method
        mediaManager.addAnnotation("String from user goes here")
    }
   @objc private func updateTableView() {
        annotationTableView.reloadData()
    }
    
    func getCurrentTimeStamp() -> Double {
    
        return 0.0
    }
    
    // MARK: Lifecycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        annotationTableView.delegate = self
        annotationTableView.dataSource = self
        mediaManager.setUpRecordingSession()
        NotificationCenter.default.addObserver(self, selector: #selector(updateTableView), name: .tableViewNeedsUpdate, object: nil)
    }
    
    
    // MARK: Tableview Delegate / DataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileManager.recordingArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: Hook this up to the currentRecording Object on the AVNManager
        let recording = fileManager.recordingArray[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        cell.textLabel?.text = recording.recordingPath.lastPathComponent
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let recording = fileManager.recordingArray[indexPath.row]
        mediaManager.playAudio(file: recording)
    }
    
}
