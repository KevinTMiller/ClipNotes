//
//  AudioRecordViewController.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/5/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import UIKit
import AVKit

enum Mode {
    case playback
    case record
}


class AudioRecordViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var isInitialFirstViewing = true
    
    @IBOutlet weak var spacerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var recordStackLeading: NSLayoutConstraint!
    @IBOutlet var recordStackTrailing: NSLayoutConstraint!
    var playStackLeading: NSLayoutConstraint?
    var playStackTrailing: NSLayoutConstraint?
    private let cellIdentifier = "annotationCell"
    let interval = 0.01
    
    @IBOutlet weak var recordStackView: UIStackView!
    @IBOutlet weak var playStackView: UIStackView!
    @IBOutlet weak var gradientView: GradientView!
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var waveformView: UIView!
    @IBOutlet weak var tempWaveformLabel: UILabel!
    @IBOutlet weak var stopWatchLabel: UILabel!
    @IBOutlet weak var recordingTitleLabel: UILabel!
    @IBOutlet weak var recordingDateLabel: UILabel!
    @IBOutlet weak var annotationTableView: UITableView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    
    // MARK: Private Vars
    
    private let mediaManager = AudioPlayerRecorder.sharedInstance
    private let fileManager = AVNManager.sharedInstance
    private var timer: Timer?
    private var gradientLayer: CAGradientLayer!
    private var isShowingRecordingView = true
    
    // MARK: Lifecycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        controlView.layer.shadowColor = UIColor.black.cgColor
        controlView.layer.shadowOpacity = 0.1
        controlView.layer.shadowRadius = 10
        controlView.layer.shadowOffset = CGSize(width: 0.0, height: 3.0)
        playStackLeading = playStackView.leadingAnchor.constraint(equalTo: controlView.leadingAnchor, constant: 5.0)
        playStackTrailing = playStackView.trailingAnchor.constraint(equalTo: controlView.trailingAnchor, constant: -5.0)
        playStackView.trailingAnchor.constraint(equalTo: recordStackView.leadingAnchor, constant: -30.0).isActive = true
        spacerHeightConstraint.constant = 1 / UIScreen.main.scale
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTableView), name: .annotationsDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUIInfo), name: .currentRecordingDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startTimer), name: .playRecordDidStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopTimer), name: .playRecordDidStop, object: nil)
        updateUIInfo()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if (isInitialFirstViewing) {
            isInitialFirstViewing = false
            switchToRecordView(true)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        switch mediaManager.currentMode {
        case .play:
            if isShowingRecordingView {
                switchToRecordView(false)
            }
        case .record:
            if !isShowingRecordingView {
                switchToRecordView(true)
            }

        }
    }
    
    
    @IBAction func refreshDidTouch(_ sender: UIBarButtonItem) {
        moveGradientPoints()
        swapViews()
    }
    @IBAction func doneButtonDidTouch(_ sender: UIButton) {
        
        switch mediaManager.currentMode {
        case .play:
            stopPlaying()
            print("Save the annotated recording")
        case .record:
            print("save and show files")
            stopRecording()
        }
    }
    
    @IBAction func playPauseDidTouch(_ sender: UIButton) {
        // TODO: Convert these to constants
        // TODO: Subclass UIButton so that these images animate
        let pauseImage = UIImage(named: "ic_pause_circle_outline_48pt")
        let playImage = UIImage(named: "ic_play_circle_outline_48pt")
        if mediaManager.currentMode == .play {
            switch mediaManager.currentState {
            case .running:
                mediaManager.pauseAudio()
                playPauseButton.setImage(playImage, for: .normal)
            case .paused:
                mediaManager.resumeAudio()
                playPauseButton.setImage(pauseImage, for: .normal)
            default:
                mediaManager.playAudio()
                playPauseButton.setImage(pauseImage, for: .normal)
            }
        }
    }
    
    @IBAction func recordButtonDidTouch(_ sender: UIButton) {
        if mediaManager.currentMode == .record {
            switch mediaManager.currentState {
            case .running:
                pauseRecording()
                print("change back to record image")
            case .paused:
                resumeRecording()
                print("change to pause button image")
            default:
                startRecording()
                print("change to pause button image")
            }
        }
        // Might want to have an edit button like apple does before allowing insertion of recordings
        if mediaManager.currentMode == .play {
            switch mediaManager.currentState {
            case .running:
                print("show an alert and ask if they want to start a new recording")
            case .paused:
                print("start recording and insert at the current time stamp of the playback")
            case .stopped:
                print("start recording at the end of the current recording")
            default:
                break
            }
        }
    }
    @IBAction func addButtonDidTouch(_ sender: UIButton) {
        showBookmarkAlert()
    }
    

   
    // MARK: Model control
    
    private func saveAndDismiss() {
        fileManager.saveFiles()
        dismiss(animated: true, completion: nil)
    }
    
    private func startRecording() {
        mediaManager.startRecordingAudio()
        updateTableView()
        startTimer()
    }
    private func stopPlaying() {
        mediaManager.stopPlayingAudio()
        performSegue(withIdentifier: "toFileView", sender: self)
    }
    
    private func stopRecording() {
        mediaManager.stopRecordingAudio()
        stopTimer()
        performSegue(withIdentifier: "toFileView", sender: self)
    }
    
    private func pauseRecording() {
        mediaManager.togglePause(pause: true)
    }
    
    private func resumeRecording(){
        mediaManager.togglePause(pause: false)
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
            self.presentAlert(title: "Error", message: "Start recording or playback to add a bookmark")
        }
    }
    @objc private func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(updateTimerLabel), userInfo: nil, repeats: true)
    }
    @objc private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func updateTimerLabel() {
        stopWatchLabel.text = mediaManager.currentTimeString ?? "00:00.00"
    }
    
    @objc private func updateTableView() {
        annotationTableView.reloadData()
    }
    // Update labels to reflect new recording info
    @objc private func updateUIInfo() {
        if let currentRecording = mediaManager.currentRecording {
        recordingTitleLabel.text = currentRecording.userTitle
        recordingDateLabel.text = DateFormatter.localizedString(from: currentRecording.date, dateStyle: .short, timeStyle: .none)
        stopWatchLabel.text = String.stringFrom(timeInterval: currentRecording.duration)
        updateTableView()
        }
    }
    // MARK: Gradient funcs
    private func createGradientLayer() {
        // color locations
        // gradient direction
        let loc2 = NSNumber(value: drand48())

        let purple = UIColor(red:0.44, green:0.47, blue:0.82, alpha:1.0).cgColor
        let darkPurple = UIColor(red:0.29, green:0.35, blue:0.80, alpha:1.0).cgColor
        let superDarkPurple = UIColor(red:0.11, green:0.17, blue:0.70, alpha:1.0).cgColor
        gradientLayer = CAGradientLayer()
        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [purple, darkPurple, superDarkPurple]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientView.layer.addSublayer(gradientLayer)
        print("locations:  \(loc2) ")
    }
    
    private func moveGradientPoints() {
        gradientView.changeGradient()
    }
    
    private func swapViews() {
        switchToRecordView(isShowingRecordingView)
        UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    private func switchToRecordView(_ isToRecordView: Bool) {
        guard let playStackLeading = playStackLeading,
            let playStackTrailing = playStackTrailing else {
            return
        }
        isShowingRecordingView = !isShowingRecordingView
        if isToRecordView {
            NSLayoutConstraint.deactivate([playStackLeading, playStackTrailing])
            NSLayoutConstraint.activate([recordStackLeading, recordStackTrailing])
        } else {
            NSLayoutConstraint.deactivate([recordStackLeading, recordStackTrailing])
            NSLayoutConstraint.activate([playStackLeading, playStackTrailing])
        }
        UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
   
    // MARK: Tableview Delegate / DataSource
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Bookmarks"
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mediaManager.currentRecording?.annotations?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.backgroundColor = UIColor.clear
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) ->
        UITableViewCell {
            guard indexPath.row < (mediaManager.currentRecording?.annotations?.count)! else {fatalError("Index row exceeds array bounds")}
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
            if let bookmark = mediaManager.currentRecording?.annotations?[indexPath.row] {
                cell.textLabel?.text = bookmark.title
                cell.detailTextLabel?.text = bookmark.noteText
            }
            return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let bookmark = mediaManager.currentRecording?.annotations?[indexPath.row] {
            if mediaManager.currentMode == .play {
                switch mediaManager.currentState {
                case .running:
                    mediaManager.skipTo(timeInterval: bookmark.timeStamp)
                case .paused:
                    mediaManager.skipTo(timeInterval: bookmark.timeStamp)
                case .stopped:
                    mediaManager.skipTo(timeInterval: bookmark.timeStamp)
                default:
                    mediaManager.playAudio()
                    mediaManager.skipTo(timeInterval: bookmark.timeStamp)
                }
            }
            if mediaManager.currentMode == .record {
                print("pop up custom modal to edit or delete bookmark")
            }
        }
    }
}
