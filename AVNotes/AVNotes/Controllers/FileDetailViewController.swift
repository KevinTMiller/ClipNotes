//
//  FileDetailViewController.swift
//  AVNotes
//
//  Created by Kevin Miller on 1/19/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

class FileDetailViewController: UIViewController{
    
    let cellIdentifier = "bookmarkCell"
    
    
    
    @IBAction func skipBackDidTouch(_ sender: UIButton) {
    }
    @IBAction func skipForwardDidTouch(_ sender: UIButton) {
    }
    @IBAction func playPauseDidTouch(_ sender: Any) {
        switch audioManager.currentState {
        case .playing:
            playPauseButton.setTitle("Resume", for: .normal)
            audioManager.pauseAudio()
            break
        case .playingPaused:
            playPauseButton.setTitle("Pause", for: .normal)
            audioManager.resumeAudio()
            break
        default:
            playPauseButton.setTitle("Pause", for: .normal)
            audioManager.playAudio(file: recording)
        }
    }
    @IBAction func addBookmarkDidTouch(_ sender: UIButton) {
    }
    @IBOutlet weak var audioProgressView: UIProgressView!
    @IBOutlet weak var bookmarkTableView: UITableView!
    @IBOutlet weak var playPauseButton: UIButton!
    
    var recording: AnnotatedRecording!
    var audioManager = AudioPlayerRecorder.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updatePlaybackControls), name: .audioPlayerDidFinish, object: nil)
    }
    
    @objc private func updatePlaybackControls() {
         playPauseButton.setTitle("Play", for: .normal)
    }
    
}
extension FileDetailViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Bookmarks"
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let bookmark = recording.annotations![indexPath.row]
        if audioManager.currentState == .playing ||
            audioManager.currentState == .playingPaused ||
            audioManager.currentState == .playingStopped {
            audioManager.skipTo(timeInterval: bookmark.timeStamp!)
        } else {
            audioManager.playAudio(file: recording)
            audioManager.skipTo(timeInterval: bookmark.timeStamp!)
        }
    }
}

extension FileDetailViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recording?.annotations?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        if let bookmark = recording?.annotations?[indexPath.row] {
            cell.textLabel?.text = bookmark.title
            cell.detailTextLabel?.text = bookmark.noteText
        }
        return cell
    }
    
}
