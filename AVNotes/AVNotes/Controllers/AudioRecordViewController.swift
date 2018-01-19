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
    
    @IBAction func stopButtonDidTouch(_ sender: UIButton) {
        stopRecording()
    }
    
    @IBAction func recordButtonDidTouch(_ sender: UIButton) {
        switch mediaManager.currentState {
        case .recording:
            pauseRecording()
        case .recordingPaused:
            resumeRecording()
        default:
            startRecording()
        }
    }
    
    
    @IBAction func addButtonDidTouch(_ sender: UIButton) {
        showBookmarkAlert()
    }
    
    // MARK: Private Vars
    
    private let mediaManager = AudioPlayerRecorder.sharedInstance
    private let fileManager = AVNManager.sharedInstance
    private var isRecording: Bool {
        return mediaManager.isRecording
    }
    private var timer: Timer?
    private var isPaused = false
    // MARK: Model control
    
    private func startRecording() {
        mediaManager.startRecordingAudio()
        updateTableView()
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateTimerLabel), userInfo: nil, repeats: true)
    }
    
    private func stopRecording() {
        mediaManager.stopRecordingAudio()
        timer?.invalidate()
        timer = nil
    }
    
    private func pauseRecording() {
        mediaManager.togglePause(on: true)
    }
    
    private func resumeRecording(){
        mediaManager.togglePause(on: false)
    }

    private func showBookmarkAlert() {
        // TODO: Am I mixing model and controller here?
        // TODO: perhaps create some var in the mediaManager that is [String: Any]
        // for all the metadata?
        if let currentRecording = mediaManager.currentRecording,
            let timeString = mediaManager.currentTimeString,
            let timeStamp = mediaManager.currentTimeInterval {
            let bookmarkNumber = String((currentRecording.annotations?.count ?? 0) + 1)
            let title = "Bookmark \(bookmarkNumber) (\(timeString))"
            self.presentBookmarkDialog(title: title, message: "Enterbookmark", completion: { (text) in
                print(text)
                self.mediaManager.addAnnotation(title: title, text: text, timestamp: timeStamp)
            })
        } else {
            self.presentAlert(title: "Error", message: "Start recording to add a bookmark")
        }
    }
    
    @objc private func updateTimerLabel() {
        if let currentTime = mediaManager.currentTimeString {
            stopWatchLabel.text = currentTime
        } else {
            stopWatchLabel.text = "00:00:00.00"
        }
    }
    
    @objc private func updateTableView() {
        annotationTableView.reloadData()
    }
    
    // MARK: Lifecycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mediaManager.setUpRecordingSession()
        NotificationCenter.default.addObserver(self, selector: #selector(updateTableView), name: .annotationsDidUpdate, object: nil)
    }
    
    
    // MARK: Tableview Delegate / DataSource
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Bookmarks"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mediaManager.currentRecording?.annotations?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) ->
        UITableViewCell {
            guard indexPath.row < (mediaManager.currentRecording?.annotations?.count)! else {fatalError("Index row exceeds array bounds")}
            
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
            if let bookmark = mediaManager.currentRecording?.annotations?[indexPath.row] {
                cell.textLabel?.text = bookmark.title ?? "No title"
                cell.detailTextLabel?.text = bookmark.noteText
            }
            return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       
    }
    
}
