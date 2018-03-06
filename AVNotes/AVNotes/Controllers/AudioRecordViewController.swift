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
        static let emptyTimeString = "00:00"
        static let animationDuation = 0.33
        static let titleFont = "montserrat"
        static let toFileView = "toFileView"
        static let emptyTableText = "No bookmarks here yet. To create a bookmark, start recording or playback and then press the add button."
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
        static let thumbImage = "ic_fiber_manual_record_white_18pt"
    }

    @IBOutlet private var audioPlotGL: EZAudioPlot!
    @IBOutlet private var recordStackLeading: NSLayoutConstraint!
    @IBOutlet private var recordStackTrailing: NSLayoutConstraint!
    @IBOutlet private var bookmarkButtonCenter: NSLayoutConstraint!
    @IBOutlet private var bookmarkButtonTrailing: NSLayoutConstraint!
    @IBOutlet private weak var recordStackView: UIStackView!
    @IBOutlet private weak var playStackView: UIStackView!
    @IBOutlet private var gradientView: GradientView!
    @IBOutlet private weak var controlView: UIView!
    @IBOutlet private weak var waveformView: BorderDrawingView!
    @IBOutlet private var scrubSlider: UISlider!
    @IBOutlet private weak var stopWatchLabel: UILabel!
    @IBOutlet private weak var recordingTitleLabel: UILabel!
    @IBOutlet private weak var recordingDateLabel: UILabel!
    @IBOutlet private weak var annotationTableView: UITableView!
    @IBOutlet private weak var recordButton: UIButton!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var addBookmarkButton: UIButton!
    @IBOutlet private weak var addButtonSuperview: UIView!

    // MARK: Private Vars
    private lazy var isInitialFirstViewing = true
    private var playStackLeading: NSLayoutConstraint?
    private var playStackTrailing: NSLayoutConstraint?
    private let mediaManager = AudioManager.sharedInstance
    private let fileManager = RecordingManager.sharedInstance
    private var timer: Timer?
    private lazy var isShowingRecordingView = true
    var plot: AKNodeOutputPlot?
    private weak var modalTransitioningDelegate = CustomModalPresentationManager()
    private lazy var gradientManager = GradientManager()
    private var buttonIsCenter = false
    private var stateManager = StateManager.sharedInstance

    // MARK: AudioKit Vars
    var microphone: AKMicrophone!
    var tracker: AKFrequencyTracker!
    var silence: AKBooster!

    // MARK: Lifecycle functions
    override func viewDidLoad() {
        super.viewDidLoad()
        AKSettings.audioInputEnabled = true
        microphone = AKMicrophone()
        tracker = AKFrequencyTracker(microphone)
        silence = AKBooster(tracker, gain: 0)
        stateManager.viewDelegate = self
        stateManager.currentState = .initialize
        definesPresentationContext = true
        NotificationCenter.default.addObserver(self, selector: #selector(updateTableView),
                                               name: .annotationsDidUpdate, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(updateUIInfo),
//                                               name: .currentRecordingDidChange, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(toggleTimer),
//                                               name: .playRecordDidStart, object: nil)
////        NotificationCenter.default.addObserver(self, selector: #selector(stopTimer),
//                                               name: .playRecordDidStop, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAfterRotate),
                                               name: .UIDeviceOrientationDidChange, object: nil)
//        updateUIInfo()
        setUpMiscUI()
//       setUpAudioPlot()
//       try? AudioKit.stop()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if isInitialFirstViewing {
            isInitialFirstViewing = false
//            switchToRecordStack(true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gradientManager.cycleGradient()
//        switch mediaManager.currentMode {
//        case .play:
//            if isShowingRecordingView {
//                switchToRecordView(false)
//            }
//        case .record:
//            if !isShowingRecordingView {
//                switchToRecordView(true)
//            }
//        }
//        updateUIInfo()
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
        stateManager.doneButtonPressed()
//        switch mediaManager.currentMode {
//        case .play:
//            stopPlaying()
//            // TODO: Implement save method
//            print("Save the annotated recording")
//        case .record:
//            print("save and show files")
//            stopRecording()
//        }
    }

    @IBAction func playPauseDidTouch(_ sender: UIButton) {
        stateManager.playButtonPressed(sender: sender)

//        let pauseImage = UIImage(named: ImageConstants.pauseImage)
//        let playImage = UIImage(named: ImageConstants.playImage)
//        if mediaManager.currentMode == .play {
//            switch mediaManager.currentState {
//            case .running:
//                mediaManager.pauseAudio()
//                playPauseButton.setImage(playImage, for: .normal)
//            case .paused:
//                mediaManager.resumeAudio()
//                playPauseButton.setImage(pauseImage, for: .normal)
//            default:
//                mediaManager.playAudio()
//                playPauseButton.setImage(pauseImage, for: .normal)
//            }
//        }
    }

    @IBAction func skipBackDidTouch(_ sender: Any) {
        mediaManager.skipFixedTime(time: -10.0)
        if timer == nil {
            updateTimerLabel()
        }
    }

    @IBAction func sliderDidSlide(_ sender: UISlider) {
        let value = Double(sender.value)
        mediaManager.skipTo(timeInterval: value)
        if timer == nil {
            updateTimerLabel()
        }
    }

    @IBAction func skipForwardDidTouch(_ sender: UIButton) {
        mediaManager.skipFixedTime(time: 10.0)
        if timer == nil {
            updateTimerLabel()
        }
    }

    @IBAction func recordButtonDidTouch(_ sender: UIButton) {
        stateManager.recordButtonPressed(sender: sender)
    }

    @IBAction func addDidTouch(_ sender: Any) {
        stateManager.addButtonPressed()
        mediaManager.switchToRecord()
    }
    
    @IBAction func addButtonDidTouch(_ sender: UIButton) {
        if stateManager.shouldShowBookmarkModal() {
            showBookmarkModal(sender: sender)
        }
    }

    // MARK: UI Funcs
    private func setUpMiscUI() {

        NSLayoutConstraint.deactivate([bookmarkButtonCenter])
        NSLayoutConstraint.activate([bookmarkButtonTrailing])

        addBookmarkButton.layer.opacity = 0.33

        playStackLeading =
            playStackView.leadingAnchor.constraint(equalTo: controlView.leadingAnchor, constant: 5.0)
        playStackTrailing =
            playStackView.trailingAnchor.constraint(equalTo: controlView.trailingAnchor, constant: -5.0)
        playStackView.trailingAnchor.constraint(equalTo: recordStackView.leadingAnchor,
                                                constant: -30.0).isActive = true
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

    private func toggleSlider(isOn: Bool) {
        if isOn {
            scrubSlider.setThumbImage(UIImage(named: ImageConstants.thumbImage), for: .normal)
            scrubSlider.isEnabled = true
            setSliderImages()
        } else {
            scrubSlider.minimumValueImage = nil
            scrubSlider.maximumValueImage = nil
            scrubSlider.setThumbImage(UIImage(), for: .disabled)
            scrubSlider.setValue(0, animated: false)
            scrubSlider.isEnabled = false
        }
    }

    private func setSliderImages() {
        if let duration = mediaManager.currentRecording?.duration {
            scrubSlider.minimumValue = 0.0
            scrubSlider.maximumValue = Float(duration)
            let timeString = String.stringFrom(timeInterval: duration)
            let image = UIImage.imageFromString(string: timeString)
            let zeroImage = UIImage.imageFromString(string: Constants.emptyTimeString)
            scrubSlider.maximumValueImage = image
            scrubSlider.minimumValueImage = zeroImage
        }
    }

    private func animateFab(active: Bool) {
        if active {
            NSLayoutConstraint.deactivate([bookmarkButtonTrailing])
            NSLayoutConstraint.activate([bookmarkButtonCenter])
            buttonIsCenter = true
        } else {
            NSLayoutConstraint.deactivate([bookmarkButtonCenter])
            NSLayoutConstraint.activate([bookmarkButtonTrailing])
            buttonIsCenter = false
        }
        UIView.animate(withDuration: 0.33,
                       delay: 0.0,
                       options: .curveEaseOut,
                       animations: { [weak self] in
                        self?.view.layoutIfNeeded()
                        self?.addBookmarkButton.isEnabled = active
                        self?.addBookmarkButton.layer.opacity = active ? 1.0 : 0.33
        }, completion: nil)
    }

    @objc
    private func refreshAfterRotate() {
        let orientation = UIDevice.current.orientation
        if orientation.isLandscape || orientation.isPortrait {
            roundedTopCornerMask(view: addButtonSuperview, size: 40.0)
            animateFab(active: buttonIsCenter)
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
    private func toggleTimer(isOn: Bool) {
        if isOn {
            timer = Timer.scheduledTimer(timeInterval: Constants.timerInterval,
                                         target: self, selector: #selector(self.updateTimerLabel),
                                         userInfo: nil, repeats: true)
            let runLoop = RunLoop.current
            runLoop.add(timer!, forMode: .UITrackingRunLoopMode)
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
    
    @objc
    private func updateTimerLabel() {
        stopWatchLabel.text = mediaManager.currentTimeString ?? Constants.emptyTimeString
        if scrubSlider.isEnabled {
            let value = mediaManager.currentTimeInterval
            scrubSlider.setValue(Float(value), animated: false)
        }
    }
    
    @objc
    private func updateTableView() {
        annotationTableView.reloadData()
    }

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

    private func resetPlot() {
        
        plot?.clear()
        plot?.plotType = .rolling
        plot?.shouldFill = true
        plot?.shouldMirror = true
        plot?.backgroundColor = .clear
        plot?.color = .white
        plot?.gain = 10
        plot?.setRollingHistoryLength(200)
    }
    
    private func setUpAudioPlot() {
//        AudioKit.output = silence
        plot = AKNodeOutputPlot(microphone, frame: CGRect())
        plot?.plotType = .rolling
        plot?.shouldFill = true
        plot?.shouldMirror = true
        plot?.backgroundColor = .clear
        plot?.color = .white
        plot?.gain = 10
        plot?.setRollingHistoryLength(200) // 200 Displays 5 sec before scrolling
        audioPlotGL.addSubview(plot!)
        plot?.translatesAutoresizingMaskIntoConstraints = false
        plot?.topAnchor.constraint(equalTo: waveformView.topAnchor).isActive = true
        plot?.bottomAnchor.constraint(equalTo: waveformView.bottomAnchor).isActive = true
        // Need to inset the view because the border drawing view draws its border inset dx 3.0 dy 3.0
        // and has a border width of 2.0. 4.0 has a nice seamless look
        plot?.leadingAnchor.constraint(equalTo: waveformView.leadingAnchor, constant: 4.0).isActive = true
        plot?.trailingAnchor.constraint(equalTo: waveformView.trailingAnchor, constant: -4.0).isActive = true
//        try? AudioKit.start()
//        try? AudioKit.stop()
    }

    private func switchToPlayStack() {
        guard let playStackLeading = playStackLeading,
            let playStackTrailing = playStackTrailing else { return }
        NSLayoutConstraint.deactivate([recordStackLeading, recordStackTrailing])
        NSLayoutConstraint.activate([playStackLeading, playStackTrailing])
        UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
        })
    }

    private func switchToRecordStack() {
        guard let playStackLeading = playStackLeading,
            let playStackTrailing = playStackTrailing else { return }
            NSLayoutConstraint.deactivate([playStackLeading, playStackTrailing])
            NSLayoutConstraint.activate([recordStackLeading, recordStackTrailing])
        UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
        })
    }
}
extension AudioRecordViewController: StateManagerViewDelegate {
    func updateButtons() {
        playPauseButton.isSelected = stateManager.playButtonSelected
        recordButton.isSelected = stateManager.recordButtonSelected
    }

    func errorAlert() {
        
    }

    func errorAlert(_ error: Error) {
        
    }

    func finishRecording() {
        updateUIInfo()
        plot?.clear()
        toggleSlider(isOn: false)
    }

    func startRecording() {
        try? AudioKit.start()
        toggleTimer(isOn: true)
        animateFab(active: true)
    }

    func prepareToPlay() {
        scrubSlider.value = 0.0
        updateUIInfo()
        plot?.clear()
        toggleSlider(isOn: true)
        switchToPlayStack()
    }

    func initialSetup() {
        updateUIInfo()
        setUpAudioPlot()
        toggleSlider(isOn: false)
        switchToRecordStack()
    }

    func prepareToRecord() {
        updateUIInfo()
        resetPlot()
        toggleSlider(isOn: false)
//        setUpAudioPlot()
        switchToRecordStack()

    }

    func playAudio() {
        toggleTimer(isOn: true)
        animateFab(active: true)
    }

    func pauseRecording() {
        try? AudioKit.stop()
        toggleTimer(isOn: false)
    }

    func resumeRecording() {
        try? AudioKit.start()
        toggleTimer(isOn: true)
    }

    func stopRecording() {
        try? AudioKit.stop()
        plot?.clear()
        toggleTimer(isOn: false)
        self.presentAlertWith(title: AlertConstants.save, message: AlertConstants.enterTitle,
                              placeholder: AlertConstants.newRecording) { [ weak self ] name in
                                if name != "" {
                                    self?.mediaManager.currentRecording?.userTitle = name
                                }
//                                self?.mediaManager.stopRecordingAudio()
//                                self?.stateManager.currentState = .prepareToRecord
//                                self?.plot?.clear()
//                                self?.recordButton.setImage(UIImage(named: ImageConstants.recordImage),
//                                                            for: .normal)
                                self?.presentAlert(title: AlertConstants.success,
                                                   message: AlertConstants.recordingSaved)
                                self?.updateUIInfo()
                                self?.stateManager.currentState = .prepareToPlay
        }
    }
}

extension AudioRecordViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        let count = mediaManager.currentRecording?.annotations?.count ?? 0
        if count == 0 && tableView.backgroundView == nil {
            tableView.isScrollEnabled = false
            let label = UILabel(frame: CGRect())
            label.text = Constants.emptyTableText
            label.textColor = UIColor.lightGray
            label.textAlignment = .center
            label.numberOfLines = 4
            label.lineBreakMode = .byWordWrapping
            tableView.backgroundView = label
            label.translatesAutoresizingMaskIntoConstraints = false
            label.widthAnchor.constraint(equalTo: tableView.widthAnchor, constant: -16.0).isActive = true
            label.leadingAnchor.constraint(equalTo: tableView.leadingAnchor, constant: 8.0).isActive = true
            label.trailingAnchor.constraint(equalTo: tableView.trailingAnchor, constant: -8.0).isActive = true
            label.topAnchor.constraint(equalTo: tableView.topAnchor).isActive = true
            label.bottomAnchor.constraint(equalTo: tableView.topAnchor,
                                          constant: 150.0).isActive = true
            return 0
        }
        if count > 0 {
            tableView.isScrollEnabled = true
            tableView.backgroundView = nil
            return 1
        }
        return 0
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
//            if mediaManager.currentMode == .play {
                scrubSlider.setValue(Float(bookmark.timeStamp), animated: false)
                switch stateManager.currentState {
                case .playing, .playingPaused, .playingStopped:
                    mediaManager.skipTo(timeInterval: bookmark.timeStamp)
                default:
                    mediaManager.playAudio()
                    mediaManager.skipTo(timeInterval: bookmark.timeStamp)
//                }
            }
        }
    }
}
