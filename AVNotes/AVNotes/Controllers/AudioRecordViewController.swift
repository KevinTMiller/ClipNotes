//
//  AudioRecordViewController.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/5/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import UIKit
import AVKit
import AudioKit
import AudioKitUI

enum Mode {
    case playback
    case record
}

let bookmarkModal = "bookmarkModal"
let mainStoryboard = "Main"

class AudioRecordViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var isInitialFirstViewing = true
    
//
//    @IBOutlet weak var controlShadowView: UIView!
    @IBOutlet weak var audioPlotGL: EZAudioPlotGL!
    @IBOutlet weak var spacerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var recordStackLeading: NSLayoutConstraint!
    @IBOutlet var recordStackTrailing: NSLayoutConstraint!
    var playStackLeading: NSLayoutConstraint?
    var playStackTrailing: NSLayoutConstraint?
    private let cellIdentifier = "annotationCell"
    let interval = 0.01
    
//    @IBOutlet weak var summaryView: EZAudioPlotGL!
    @IBOutlet weak var recordStackView: UIStackView!
    @IBOutlet weak var playStackView: UIStackView!
    @IBOutlet weak var gradientView: GradientView!
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var waveformView: BorderDrawingView!
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
    private var plot: AKNodeOutputPlot?
    private var modalTransitioningDelegate = CustomModalPresentationManager()
    
    // MARK: Lifecycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        controlShadowView.layer.shadowColor = UIColor.black.cgColor
//        controlShadowView.layer.shadowOpacity = 0.1
//        controlShadowView.layer.shadowRadius = 10
//        controlShadowView.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
//
        definesPresentationContext = true
        
        playStackLeading = playStackView.leadingAnchor.constraint(equalTo: controlView.leadingAnchor, constant: 5.0)
        playStackTrailing = playStackView.trailingAnchor.constraint(equalTo: controlView.trailingAnchor, constant: -5.0)
        playStackView.trailingAnchor.constraint(equalTo: recordStackView.leadingAnchor, constant: -30.0).isActive = true
        spacerHeightConstraint.constant = 1 / UIScreen.main.scale
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateTableView), name: .annotationsDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUIInfo), name: .currentRecordingDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startTimer), name: .playRecordDidStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopTimer), name: .playRecordDidStop, object: nil)
        updateUIInfo()
        setUpAudioPlot()
        AudioKit.stop()
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
//            showSummaryWaveform()
            if isShowingRecordingView {
                switchToRecordView(false)
            }
        case .record:
            if !isShowingRecordingView {
                switchToRecordView(true)
            }
        }
        updateUIInfo()
        gradientView.changeGradient()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        audioPlotGL.backgroundColor = .clear
        navigationController?.navigationBar.backgroundColor = .clear
    }
    
    // MARK: IBActions
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
    
    @IBAction func skipBackDidTouch(_ sender: Any) {
        mediaManager.skipFixedTime(time: -10.0)
    }
    @IBAction func skipForwardDidTouch(_ sender: UIButton) {
        mediaManager.skipFixedTime(time: 10.0)
    }
    
    @IBAction func recordButtonDidTouch(_ sender: UIButton) {
        if mediaManager.currentMode == .record {
            switch mediaManager.currentState {
            case .running:
                pauseRecording()
                sender.setImage(UIImage(named:"ic_fiber_manual_record_48pt"), for: .normal)
            case .paused:
                resumeRecording()
                sender.setImage(UIImage(named:"ic_pause_circle_outline_48pt"), for: .normal)
            default:
                startRecording()
                sender.setImage(UIImage(named:"ic_pause_circle_outline_48pt"), for: .normal)
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
    @IBAction func addDidTouch(_ sender: Any) {
        mediaManager.switchToRecord()
        switchToRecordView(true)
    }
    @IBAction func addButtonDidTouch(_ sender: UIButton) {
        showBookmarkModal(sender: sender)
    }
    
    // MARK: Model control

    private func saveAndDismiss() {
        fileManager.saveFiles()
        dismiss(animated: true, completion: nil)
    }
    
    private func startRecording() {
        
        mediaManager.startRecordingAudio()
        setUpAudioPlot()
        AudioKit.start()
        updateTableView()
        startTimer()
    }
    
    private func stopPlaying() {
        mediaManager.stopPlayingAudio()
        
        if let plot = plot {
            plot.clear()
        }
        performSegue(withIdentifier: "toFileView", sender: self)
    }
    
    private func stopRecording() {
        pauseRecording()
        stopTimer()
        self.presentAlertWith(title: "Save", message: "Enter a title for this recording", placeholder: "New Recording") { (name) in
            if name != "" {
                self.mediaManager.currentRecording?.userTitle = name
            }
            self.mediaManager.stopRecordingAudio()
            self.plot?.clear()
            self.performSegue(withIdentifier: "toFileView", sender: self)
        }
    }
    
    private func pauseRecording() {
        mediaManager.togglePause(pause: true)
        AudioKit.stop()

    }
    
    private func resumeRecording(){
        mediaManager.togglePause(pause: false)
        AudioKit.start()
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
            self.presentAlertWith(title: title, message: "Enter bookmark", placeholder: "Type bookmark Text Here", completion: { (text) in
                print(text)
                self.mediaManager.addAnnotation(title: title, text: text, timestamp: timeStamp)
            })
        } else {
            self.presentAlert(title: "Error", message: "Start recording or playback to add a bookmark")
        }
    }
    // MARK: UI Funcs
    @objc func showBookmarkModal(sender: Any) {
        
        let bookmarkVC = UIStoryboard(name: mainStoryboard, bundle: nil).instantiateViewController(withIdentifier: bookmarkModal) as! BookmarkModalViewController
        bookmarkVC.modalPresentationStyle = .custom
        bookmarkVC.transitioningDelegate = modalTransitioningDelegate
        
        if sender is UIButton {
            bookmarkVC.bookmarkType = .create
        }
        if let sender = sender as? UILongPressGestureRecognizer,
            let tableviewCell = sender.view as? BookmarkTableViewCell {
            bookmarkVC.bookmarkType = .edit
            bookmarkVC.currentBookmarkIndexPath = tableviewCell.indexPath
        }
        present(bookmarkVC, animated: true, completion: nil)
        
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
    // AudioKit funcs
    
//    private func showSummaryWaveform() {
//        if let plot = mediaManager.getPlotFromCurrentRecording(),
//            let scrollPlot = mediaManager.getPlotFromCurrentRecording(){
//            scrollPlot.frame = audioPlotGL.bounds
//            plot.frame = summaryView.bounds
//            scrollPlot.plotType = .rolling
//            scrollPlot.setRollingHistoryLength(100)
////            scrollPlot.displayLinkNeedsDisplay(EZAudioDisplayLink!)
////            summaryView.addSubview(plot)
//            audioPlotGL.addSubview(scrollPlot)
//        }
//    }
    
    private func setUpAudioPlot() {
        
        if let mic = mediaManager.mic {
            if plot == nil {
                plot = AKNodeOutputPlot(mic, frame: audioPlotGL.bounds)
            }
            plot?.plotType = .rolling
            plot?.shouldFill = true
            plot?.shouldMirror = true
            plot?.backgroundColor = .clear
            plot?.color = .white
            plot?.gain = 3
            plot?.setRollingHistoryLength(200) // 200 Displays 5 sec before scrolling
            audioPlotGL.addSubview(plot!)
            }
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = .clear
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .light)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mediaManager.currentRecording?.annotations?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) ->
        UITableViewCell {
            guard indexPath.row < (mediaManager.currentRecording?.annotations?.count)! else {fatalError("Index row exceeds array bounds")}
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? BookmarkTableViewCell,
                let bookmark = mediaManager.currentRecording?.annotations?[indexPath.row] {
                cell.bookmarkTextLabel?.text = bookmark.noteText
                cell.bookmarkTitleLabel?.text = bookmark.title
                cell.bookmarkTimeStamp?.text = String.stringFrom(timeInterval: bookmark.timeStamp)
                cell.indexPath = indexPath
                
                // TODO: Figure out how to check for targets
                
                cell.longPressRecognizer.addTarget(self, action: #selector(showBookmarkModal))
//                cell.addGestureRecognizer(cell.longPressRecognizer)
                return cell
            }
            return tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
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
        }
    }
}
