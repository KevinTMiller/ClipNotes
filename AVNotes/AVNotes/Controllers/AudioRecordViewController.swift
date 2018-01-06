//
//  AudioRecordViewController.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/5/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import UIKit
import AVKit



class AudioRecordViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let cellIdentifier = "annotationCell"
    
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
    
    private let mediaManager = AudioVideoRecorder.sharedInstance
    private let fileManager = AVNManager.sharedInstance
    private var isRecording: Bool {
        return mediaManager.isRecording
    }
    
    // MARK: Model control
    
    private func startRecording() {
        mediaManager.stopRecordingAudio()
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
        mediaManager.setUpRecordingSession()
        NotificationCenter.default.addObserver(self, selector: #selector(updateTableView), name: .annotationsDidUpdate, object: nil)
    }
    
    
    // MARK: Tableview Delegate / DataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileManager.recordingArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) ->
        UITableViewCell {
        guard indexPath.row < fileManager.recordingArray.count else {fatalError("Index row exceeds array bounds")}
        let recording = fileManager.recordingArray[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        cell.textLabel?.text = recording.userTitle
        cell.detailTextLabel?.text = recording.fileName
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < fileManager.recordingArray.count else {fatalError("Index row exceeds array bounds")}
        let recording = fileManager.recordingArray[indexPath.row]
        mediaManager.playAudio(file: recording)
    }
    
}
