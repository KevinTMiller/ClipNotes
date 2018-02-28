//
//  AudioRecordViewController.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/5/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import AudioKit
import AudioKitUI
import AVKit
import UIKit

enum Mode {
    case playback
    case record
}

let bookmarkModal = "bookmarkModal"
let mainStoryboard = "Main"

class AudioRecordViewController: UIViewController {
    
    enum Constants {
        static let bookmarkModal = "bookmarkModal"
        static let mainStoryboard = "Main"
        static let cellIdentifier = "annotationCell"
        static let recordAlertTitle = "Press Record"
        static let recordAlertMessage = "Start recording before adding a bookmark"
        static let timerInterval = 0.01
        static let emptyTimeString = "00:00.00"
        static let animationDuation = 0.33
        static let titleFont = "montserrat"
        static let toFileView = "toFileView"
    }

    enum AlertConstants {
        static let save = "Save"
        static let success = "Success"
        static let enterTitle = "Enter a title for this recording"
        static let newRecording = "New Recording"
        static let recordingSaved = "Your recording has been saved."
    }

    enum ImageConstants {
        static let pauseImage = "ic_pause_circle_outline_48pt"
        static let recordImage = "ic_fiber_manual_record_48pt"
        static let playImage = "ic_play_circle_outline_48pt"
    }

    @IBOutlet private weak var audioPlotGL: EZAudioPlot!
    @IBOutlet private weak var spacerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var recordStackLeading: NSLayoutConstraint!
    @IBOutlet private var recordStackTrailing: NSLayoutConstraint!

    @IBOutlet private weak var recordStackView: UIStackView!
    @IBOutlet private weak var playStackView: UIStackView!
    @IBOutlet private var gradientView: GradientView!
    @IBOutlet private weak var controlView: UIView!
    @IBOutlet private weak var waveformView: BorderDrawingView!
    @IBOutlet private weak var stopWatchLabel: UILabel!
    @IBOutlet private weak var recordingTitleLabel: UILabel!
    @IBOutlet private weak var recordingDateLabel: UILabel!
    @IBOutlet private weak var annotationTableView: UITableView!
    @IBOutlet private weak var recordButton: UIButton!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var addBookmarkButton: UIButton!
    @IBOutlet private weak var addButtonSuperview: UIView!

    // MARK: Private Vars
    private var isInitialFirstViewing = true
    private var playStackLeading: NSLayoutConstraint?
    private var playStackTrailing: NSLayoutConstraint?
    private let mediaManager = AudioPlayerRecorder.sharedInstance
    private let fileManager = AVNManager.sharedInstance
    private var timer: Timer?
    private var isShowingRecordingView = true
    private var plot: AKNodeOutputPlot?
    private weak var modalTransitioningDelegate = CustomModalPresentationManager()
    private var gradientManager = GradientManager()

    // MARK: Lifecycle functions
    override func viewDidLoad() {
        super.viewDidLoad()
        definesPresentationContext = true
        NotificationCenter.default.addObserver(self, selector: #selector(updateTableView),
                                               name: .annotationsDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUIInfo),
                                               name: .currentRecordingDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startTimer),
                                               name: .playRecordDidStart, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopTimer),
                                               name: .playRecordDidStop, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAfterRotate),
                                               name: .UIDeviceOrientationDidChange, object: nil)
        updateUIInfo()
        setUpMiscUI()
        setUpAudioPlot()
        try? AudioKit.stop()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if isInitialFirstViewing {
            isInitialFirstViewing = false
            switchToRecordView(true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gradientManager.cycleGradient()
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
        updateUIInfo()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = .lightContent
        setNeedsStatusBarAppearanceUpdate()
        audioPlotGL.backgroundColor = .clear
        navigationController?.navigationBar.backgroundColor = .clear
    }

    // MARK: IBActions
    @IBAction func doneButtonDidTouch(_ sender: UIButton) {
        switch mediaManager.currentMode {
        case .play:
            stopPlaying()
            // TODO: Implement save method
            print("Save the annotated recording")
        case .record:
            print("save and show files")
            stopRecording()
        }
    }

    @IBAction func playPauseDidTouch(_ sender: UIButton) {
        let pauseImage = UIImage(named: ImageConstants.pauseImage)
        let playImage = UIImage(named: ImageConstants.playImage)
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
                sender.setImage(UIImage(named: ImageConstants.recordImage), for: .normal)
            case .paused:
                resumeRecording()
                sender.setImage(UIImage(named: ImageConstants.pauseImage), for: .normal)
            default:
                startRecording()
                sender.setImage(UIImage(named: ImageConstants.pauseImage), for: .normal)
            }
        }

        if mediaManager.currentMode == .play {
            switch mediaManager.currentState {
            // TODO: Implement these
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
        switch mediaManager.currentState {
        case .running:
            showBookmarkModal(sender: sender)
        case .paused:
            showBookmarkModal(sender: sender)
        default:
            presentAlert(title: Constants.recordAlertTitle, message: Constants.recordAlertMessage)
        }
    }

    // MARK: Model control

    private func saveAndDismiss() {
        fileManager.saveFiles()
        dismiss(animated: true, completion: nil)
    }

    private func startRecording() {
        mediaManager.startRecordingAudio()
        setUpAudioPlot()
        try? AudioKit.start()
        updateTableView()
        startTimer()
    }

    private func stopPlaying() {
        mediaManager.stopPlayingAudio()
        if let plot = plot {
            plot.clear()
        }
        performSegue(withIdentifier: Constants.toFileView, sender: self)
    }

    private func stopRecording() {
        pauseRecording()
        stopTimer()
        self.presentAlertWith(title: AlertConstants.save, message: AlertConstants.enterTitle,
                              placeholder: AlertConstants.newRecording) { [ weak self ] name in
                                if name != "" {
                                    self?.mediaManager.currentRecording?.userTitle = name
                                }
                                self?.mediaManager.stopRecordingAudio()
                                self?.plot?.clear()
                                self?.recordButton.setImage(UIImage(named: ImageConstants.recordImage),
                                                            for: .normal)
                                self?.presentAlert(title: AlertConstants.success,
                                                   message: AlertConstants.recordingSaved)
        }
    }

    private func pauseRecording() {
        mediaManager.togglePause(pause: true)
        try? AudioKit.stop()
    }

    private func resumeRecording() {
        mediaManager.togglePause(pause: false)
        try? AudioKit.start()
    }

    // MARK: UI Funcs
    private func setUpMiscUI() {
        playStackLeading =
            playStackView.leadingAnchor.constraint(equalTo: controlView.leadingAnchor, constant: 5.0)
        playStackTrailing =
            playStackView.trailingAnchor.constraint(equalTo: controlView.trailingAnchor, constant: -5.0)
        playStackView.trailingAnchor.constraint(equalTo: recordStackView.leadingAnchor,
                                                constant: -30.0).isActive = true
        spacerHeightConstraint.constant = 1 / UIScreen.main.scale
        let navBarAttributes = [
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.font: UIFont(name: Constants.titleFont, size: 18)!]
        navigationController?.navigationBar.titleTextAttributes = navBarAttributes

        roundedTopCornerMask(view: addButtonSuperview, size: 40.0)
        addButtonSuperview.clipsToBounds = false
        addBookmarkButton.layer.shadowColor = UIColor.black.cgColor
        addBookmarkButton.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        addBookmarkButton.layer.masksToBounds = false
        addBookmarkButton.layer.shadowRadius = 2.0
        addBookmarkButton.layer.shadowOpacity = 0.25
        addBookmarkButton.layer.cornerRadius = addBookmarkButton.frame.width / 2
        gradientView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        gradientManager.addManagedView(gradientView)
        gradientManager.addManagedView(addBookmarkButton)
    }

    @objc
    private func refreshAfterRotate() {
        let orientation = UIDevice.current.orientation
        if orientation.isLandscape || orientation.isPortrait {
            roundedTopCornerMask(view: addButtonSuperview, size: 40.0)
        }
    }

    private func roundedTopCornerMask(view: UIView, size: Double ) {

        let cornerRadius = CGSize(width: size, height: size)
        let maskPath = UIBezierPath(roundedRect: view.bounds,
                                    byRoundingCorners: [.topLeft, .topRight],
                                    cornerRadii: cornerRadius)
        let shape = CAShapeLayer()
        shape.path = maskPath.cgPath
        view.layer.mask = shape
    }

    @objc
    func showBookmarkModal(sender: Any) {
        guard let bookmarkVC =
            UIStoryboard(name: mainStoryboard,
                         bundle: nil).instantiateViewController(withIdentifier: bookmarkModal)
                as? BookmarkModalViewController else { return }
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

    @objc
    private func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: Constants.timerInterval,
                                     target: self, selector: #selector(self.updateTimerLabel),
                                     userInfo: nil, repeats: true)
        let runLoop = RunLoop.current
        runLoop.add(timer!, forMode: .UITrackingRunLoopMode)
    }

    @objc
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc
    private func updateTimerLabel() {
        stopWatchLabel.text = mediaManager.currentTimeString ?? Constants.emptyTimeString
    }
    
    @objc
    private func updateTableView() {
        annotationTableView.reloadData()
    }

    // Update labels to reflect new recording info
    @objc
    private func updateUIInfo() {
        if let currentRecording = mediaManager.currentRecording {
            recordingTitleLabel.text = currentRecording.userTitle
            recordingDateLabel.text = DateFormatter.localizedString(from: currentRecording.date,
                                                                    dateStyle: .short,
                                                                    timeStyle: .none)
            stopWatchLabel.text = String.stringFrom(timeInterval: currentRecording.duration)
            updateTableView()
        }
    }

    private func setUpAudioPlot() {

        if let mic = mediaManager.akMicrophone {
            if plot == nil {
                plot = AKNodeOutputPlot(mic, frame: audioPlotGL.bounds)
            }
            plot?.plotType = .rolling
            plot?.shouldFill = true
            plot?.shouldMirror = true
            plot?.backgroundColor = .clear
            plot?.color = .white
            plot?.gain = 3
            plot?.shouldOptimizeForRealtimePlot = true
            plot?.setRollingHistoryLength(200) // 200 Displays 5 sec before scrolling
            audioPlotGL.addSubview(plot!)
        }
    }

    private func swapViews() {
        switchToRecordView(isShowingRecordingView)
        UIView.animate(withDuration: Constants.animationDuation, delay: 0,
                       options: .curveEaseInOut, animations: {
                        self.view.layoutIfNeeded()
        })
    }

    private func switchToRecordView(_ isToRecordView: Bool) {
        guard let playStackLeading = playStackLeading,
            let playStackTrailing = playStackTrailing else { return }
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
}

extension AudioRecordViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mediaManager.currentRecording?.annotations?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) ->
        UITableViewCell {
            guard indexPath.row < (mediaManager.currentRecording?.annotations?.count)!
                else { fatalError("Index row exceeds array bounds") }

            if let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier)
                as? BookmarkTableViewCell,
                let bookmark = mediaManager.currentRecording?.annotations?[indexPath.row] {

                cell.populateFromBookmark(bookmark, index: indexPath)

                if cell.longPressRecognizer == nil {
                    cell.longPressRecognizer = UILongPressGestureRecognizer()
                }
                cell.longPressRecognizer.addTarget(self, action: #selector(showBookmarkModal))
                cell.addGestureRecognizer(cell.longPressRecognizer)
                return cell
            }
            return tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier)!
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
