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
        static let animationDuation = 0.33
        static let bookmarkModal = "bookmarkModal"
        static let cellIdentifier = "annotationCell"
        static let emptyTableText = "No bookmarks here yet. To create a bookmark, start recording or playback and then press the add button." // swiftlint:disable:this line_length
        static let emptyTimeString = "00:00.00"
        static let insetConstant: CGFloat = 3.0
        static let mainStoryboard = "Main"
        static let playbackLineWidth: CGFloat = 1 / UIScreen.main.scale
        static let recordAlertMessage = "Start recording before adding a bookmark"
        static let recordAlertTitle = "Press Record"
        static let trailingInset: CGFloat = 0.06
        static let tableViewInset: CGFloat = 8.0
        static let timerInterval = 0.03
        static let titleFont = "montserrat"
        static let toFileView = "toFileView"
        static let viewSize: CGFloat = 150.0
    }

    enum AlertConstants {
        static let bookmarks = "Bookmarks"
        static let cancel = "Cancel"
        static let enterTitle = "Enter a title for this recording"
        static let export = "Export:"
        static let newRecording = "New Recording"
        static let recording = "Recording"
        static let recordingSaved = "Your recording has been saved."
        static let save = "Save"
        static let success = "Success"
    }

    enum ImageConstants {
        static let pauseImage = "ic_pause_circle_outline_48pt"
        static let playImage = "ic_play_circle_outline_48pt"
        static let recordImage = "ic_fiber_manual_record_48pt"
        static let thumbImage = "ic_fiber_manual_record_white_18pt"
    }

    // MARK: IBOutlets
    @IBOutlet private weak var addBookmarkButton: UIButton!
    @IBOutlet private weak var addButtonSuperview: UIView!
    @IBOutlet private weak var annotationTableView: UITableView!
    @IBOutlet private var audioPlot: EZAudioPlot!
    @IBOutlet private var bookmarkButtonCenter: NSLayoutConstraint!
    @IBOutlet private var bookmarkButtonTrailing: NSLayoutConstraint!
    @IBOutlet private weak var controlView: UIView!
    @IBOutlet private var filesButton: UIBarButtonItem!
    @IBOutlet private var gradientView: GradientView!
    @IBOutlet private weak var playPauseButton: UIButton!
    @IBOutlet private weak var playStackView: UIStackView!
    @IBOutlet private var plusButton: UIBarButtonItem!
    @IBOutlet private weak var recordButton: UIButton!
    @IBOutlet private weak var recordingDateLabel: UILabel!
    @IBOutlet private weak var recordingTitleLabel: UILabel!
    @IBOutlet private var recordStackLeading: NSLayoutConstraint!
    @IBOutlet private var recordStackTrailing: NSLayoutConstraint!
    @IBOutlet private weak var recordStackView: UIStackView!
    @IBOutlet private var scrubSlider: UISlider!
    @IBOutlet private var shareButton: UIBarButtonItem!
    @IBOutlet private weak var stopWatchLabel: UILabel!
    @IBOutlet private weak var waveformView: BorderDrawingView!

    // MARK: Private Vars
    private var isButtonCenter = false
    private let fileManager = RecordingManager.sharedInstance
    private lazy var gradientManager = GradientManager()
    private lazy var isInitialFirstViewing = true
    private lazy var isShowingRecordingView = true
    private let mediaManager = AudioManager.sharedInstance
    private weak var modalTransitioningDelegate = CustomModalPresentationManager()
    private var playbackLine: UIView?
    private var playbackLineCenter: NSLayoutConstraint?
    private var playStackLeading: NSLayoutConstraint?
    private var playStackTrailing: NSLayoutConstraint?
    private var stateManager = StateManager.sharedInstance
    private var timer: Timer?

    // MARK: AudioKit Vars
    private var microphone: AKMicrophone!
    private var livePlot: AKNodeOutputPlot?
    private var summaryPlot: EZAudioPlot?

    // MARK: Lifecycle functions
    override func viewDidLoad() {
        super.viewDidLoad()
        AKSettings.audioInputEnabled = true
        microphone = AKMicrophone()
        stateManager.viewDelegate = self
        stateManager.currentState = .initialize
        mediaManager.bookmarkTableViewDelegate = self
        definesPresentationContext = true
        NotificationCenter.default.addObserver(self, selector: #selector(refreshAfterRotate),
                                               name: .UIDeviceOrientationDidChange, object: nil)
        setUpMiscUI()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if isInitialFirstViewing {
            isInitialFirstViewing = false
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gradientManager.cycleGradient()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = .lightContent
        setNeedsStatusBarAppearanceUpdate()
        audioPlot.backgroundColor = .clear
        navigationController?.navigationBar.backgroundColor = .clear
    }

    // MARK: IBActions
    @IBAction func shareButtonTapped(_ sender: UIBarButtonItem) {
        showShareAlertSheet()
    }

    @IBAction func doneButtonDidTouch(_ sender: UIButton) {
        stateManager.endRecording()
    }

    @IBAction func playPauseDidTouch(_ sender: UIButton) {
        stateManager.togglePlayState(sender: sender)
    }

    @IBAction func skipBackDidTouch(_ sender: Any) {
        mediaManager.skipFixedTime(time: -10.0)
        if timer == nil {
            updateTimerDependentUI()
        }
    }

    @IBAction func sliderDidSlide(_ sender: UISlider) {
        let value = Double(sender.value)
        mediaManager.skipTo(timeInterval: value)
        if timer == nil {
            updateTimerDependentUI()
        }
    }

    @IBAction func skipForwardDidTouch(_ sender: UIButton) {
        mediaManager.skipFixedTime(time: 10.0)
        if timer == nil {
            updateTimerDependentUI()
        }
    }

    @IBAction func recordButtonDidTouch(_ sender: UIButton) {
        stateManager.toggleRecordingState(sender: sender)
    }

    @IBAction func addDidTouch(_ sender: Any) {
        mediaManager.switchToRecord()
    }
    
    @IBAction func addButtonDidTouch(_ sender: UIButton) {
        if stateManager.allowsAnnotation() {
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

        createPlaybackLine()
        roundedTopCornerMask(view: addButtonSuperview, size: 40.0)
        addButtonSuperview.clipsToBounds = false
        addBookmarkButton.layer.shadowColor = UIColor.black.cgColor
        addBookmarkButton.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        addBookmarkButton.layer.masksToBounds = false
        addBookmarkButton.layer.shadowRadius = 2.0
        addBookmarkButton.layer.shadowOpacity = 0.25
        gradientView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        gradientManager.addManagedView(gradientView)
        gradientManager.addManagedView(addBookmarkButton)
        addBookmarkButton.layer.cornerRadius = addBookmarkButton.frame.width / 2
        addBookmarkButton.clipsToBounds = true

        let panGestureRecognizer = UIPanGestureRecognizer(target: self,
                                                          action: #selector(waveformDidPan))
        waveformView.addGestureRecognizer(panGestureRecognizer)
    }

    private func createPlaybackLine() {
        playbackLine = UIView()
        waveformView.addSubview(playbackLine!)
        playbackLine?.backgroundColor = .white
        playbackLine?.widthAnchor.constraint(equalToConstant: Constants.playbackLineWidth).isActive = true // swiftlint:disable:this line_length
        playbackLine?.topAnchor.constraint(equalTo: waveformView.topAnchor,
                                           constant: Constants.insetConstant).isActive = true
        playbackLine?.bottomAnchor.constraint(equalTo: waveformView.bottomAnchor,
                                              constant: -Constants.insetConstant).isActive = true
        playbackLineCenter = playbackLine?.centerXAnchor.constraint(equalTo: waveformView.leadingAnchor) // swiftlint:disable:this line_length
        playbackLineCenter?.isActive = true
        playbackLine?.translatesAutoresizingMaskIntoConstraints = false
        playbackLine?.isHidden = false
    }

    private func showShareAlertSheet() {
        let alert = UIAlertController(title: AlertConstants.export,
                                      message: nil,
                                      preferredStyle: .actionSheet)
        let bookmarks = UIAlertAction(title: AlertConstants.bookmarks,
                                      style: .default) { [weak self] _ in
            self?.exportBookmarks()
        }
        let recording = UIAlertAction(title: AlertConstants.recording,
                                      style: .default) { [weak self] _ in
            self?.exportRecording()
        }
        let cancel = UIAlertAction(title: AlertConstants.cancel, style: .cancel, handler: nil)
        alert.addAction(bookmarks)
        alert.addAction(recording)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }

    private func exportRecording() {
        guard let currentRecording = mediaManager.currentRecording else { return }

        let fileName = currentRecording.fileName
        let userName = "\(currentRecording.userTitle).m4a"
        let originPath = mediaManager.getDocumentsDirectory().appendingPathComponent(fileName)
        let tempPath = FileManager.default.temporaryDirectory.appendingPathComponent(userName)
        try? FileManager.default.copyItem(at: originPath, to: tempPath)
        let activityController = UIActivityViewController(activityItems: [tempPath],
                                                          applicationActivities: nil)
        present(activityController, animated: true, completion: nil)

    }

    private func exportBookmarks() {
        guard let currentRecording = mediaManager.currentRecording else { return }
        if let stringURL = AnnotatedRecording.formatBookmarksForExport(recording: currentRecording) {
            let activityController = UIActivityViewController(activityItems: [stringURL],
                                                              applicationActivities: nil)
            present(activityController, animated: true, completion: nil)
        }
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
        guard let duration = mediaManager.currentRecording?.duration else { return }
        scrubSlider.minimumValue = 0.0
        scrubSlider.maximumValue = Float(duration)
        let timeString = String.stringFrom(timeInterval: duration)
        let image = UIImage.imageFromString(string: timeString)
        let zeroImage = UIImage.imageFromString(string: Constants.emptyTimeString)
        scrubSlider.maximumValueImage = image
        scrubSlider.minimumValueImage = zeroImage
    }

    private func animateFab(active: Bool) {
        if active {
            NSLayoutConstraint.deactivate([bookmarkButtonTrailing])
            NSLayoutConstraint.activate([bookmarkButtonCenter])
            isButtonCenter = true
        } else {
            NSLayoutConstraint.deactivate([bookmarkButtonCenter])
            NSLayoutConstraint.activate([bookmarkButtonTrailing])
            isButtonCenter = false
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
    private func waveformDidPan(sender: UIPanGestureRecognizer) {
        guard stateManager.isPlayMode else { return }
        guard let end = mediaManager.currentRecording?.duration else { return }
        let offset = sender.location(in: waveformView).x
        let seconds = end / Double(waveformView.bounds.maxX / offset)
        let skipTime = seconds - mediaManager.currentTimeInterval
        mediaManager.skipFixedTime(time: skipTime)
        if timer == nil {
            updateTimerDependentUI()
        }
    }

    private func movePlaybackLine(value: Double) {
        let waveformViewMax = Float(waveformView.bounds.maxX)
        let maxSeconds = scrubSlider.maximumValue
        let offset: Float
        if value > 0 {
            offset = waveformViewMax / (maxSeconds / Float(value))
        } else {
            offset = 0
        }
        playbackLineCenter?.constant = CGFloat(offset)
    }

    @objc
    private func refreshAfterRotate() {
        let orientation = UIDevice.current.orientation
        if orientation.isLandscape || orientation.isPortrait {
            roundedTopCornerMask(view: addButtonSuperview, size: 40.0)
            animateFab(active: isButtonCenter)
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
                                         target: self, selector: #selector(self.updateTimerDependentUI),
                                         userInfo: nil, repeats: true)
            let runLoop = RunLoop.current
            runLoop.add(timer!, forMode: .UITrackingRunLoopMode)
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
    
    @objc
    private func updateTimerDependentUI() {
        stopWatchLabel.text = mediaManager.currentTimeString ?? Constants.emptyTimeString
        if scrubSlider.isEnabled {
            let value = mediaManager.currentTimeInterval
            scrubSlider.setValue(Float(value), animated: false)
            movePlaybackLine(value: value)
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
        summaryPlot?.removeFromSuperview()
        livePlot?.clear()
        livePlot?.plotType = .rolling
        livePlot?.shouldFill = true
        livePlot?.shouldMirror = true
        livePlot?.backgroundColor = .clear
        livePlot?.color = .white
        livePlot?.gain = 2
        livePlot?.setRollingHistoryLength(200)
    }

    private func setSummaryPlot() {
        summaryPlot?.removeFromSuperview()
        summaryPlot = mediaManager.getPlotFromCurrentRecording()
        audioPlot.addSubview(summaryPlot!)
        // Setting the frame or bounds causes misalignment upon rotation
        // Use autolayout constraints instead
        summaryPlot?.translatesAutoresizingMaskIntoConstraints = false
        summaryPlot?.topAnchor.constraint(equalTo: waveformView.topAnchor).isActive = true
        summaryPlot?.bottomAnchor.constraint(equalTo: waveformView.bottomAnchor).isActive = true
        // Need to inset the view because the border drawing view draws its border inset dx 3.0 dy 3.0
        // and has a border width of 2.0. 4.0 has a nice seamless look
                summaryPlot?.leadingAnchor.constraint(equalTo: waveformView.leadingAnchor,
                                              constant: Constants.insetConstant).isActive = true
        let trailing = waveformView.bounds.width * Constants.trailingInset
        summaryPlot?.trailingAnchor.constraint(equalTo: waveformView.trailingAnchor,
                                               constant: -trailing).isActive = true

    }
    
    private func setUpAudioPlot() {
        livePlot = AKNodeOutputPlot(microphone, frame: CGRect())
        livePlot?.plotType = .rolling
        livePlot?.shouldFill = true
        livePlot?.shouldMirror = true
        livePlot?.backgroundColor = .clear
        livePlot?.color = .white
        livePlot?.gain = 3
        livePlot?.setRollingHistoryLength(200) // 200 Displays 5 sec before scrolling
        audioPlot.addSubview(livePlot!)
        livePlot?.translatesAutoresizingMaskIntoConstraints = false
        livePlot?.topAnchor.constraint(equalTo: waveformView.topAnchor).isActive = true
        livePlot?.bottomAnchor.constraint(equalTo: waveformView.bottomAnchor).isActive = true
        // Need to inset the view because the border drawing view draws its border inset dx 3.0 dy 3.0
        // and has a border width of 2.0. 4.0 has a nice seamless look
        livePlot?.leadingAnchor.constraint(equalTo: waveformView.leadingAnchor,
                                           constant: Constants.insetConstant).isActive = true 
        let trailing = waveformView.bounds.width * Constants.trailingInset
        livePlot?.trailingAnchor.constraint(equalTo: waveformView.trailingAnchor,
                                            constant: -trailing).isActive = true

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
        if stateManager.isRecordMode {
            playbackLineCenter?.constant = 0.0
        }
        UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
            self.playbackLine?.isHidden = self.stateManager.isRecordMode
            self.shareButton.isEnabled = self.stateManager.canShare
            self.playPauseButton.isSelected = self.stateManager.isPlaying
            self.recordButton.isSelected = self.stateManager.isRecording
            self.plusButton.isEnabled = self.stateManager.canAnnotate
            self.filesButton.isEnabled = self.stateManager.canViewFiles
        })

    }

    func errorAlert(_ error: Error) {
        // TODO: Implement this so it can show errors from the state manager
    }

    func finishRecording() {
        updateButtons()
        updateUIInfo()
        livePlot?.clear()
        toggleSlider(isOn: false)
    }

    func startRecording() {
        try? AudioKit.start()
        updateButtons()
        toggleTimer(isOn: true)
        animateFab(active: true)
    }

    func prepareToPlay() {
        updateButtons()
        scrubSlider.value = 0.0
        updateUIInfo()
        livePlot?.clear()
        setSummaryPlot()
        toggleSlider(isOn: true)
        animateFab(active: true)
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
        updateButtons()
        resetPlot()
        toggleSlider(isOn: false)
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
        livePlot?.clear()
        toggleTimer(isOn: false)
        self.presentAlertWith(title: AlertConstants.save,
                              message: AlertConstants.enterTitle,
                              placeholder: AlertConstants.newRecording) { [ weak self ] name in
                                if name != "" {
                                    self?.mediaManager.currentRecording?.userTitle = name
                                }
                                self?.presentAlert(title: AlertConstants.success,
                                                   message: AlertConstants.recordingSaved)
                                self?.updateUIInfo()
                                self?.stateManager.currentState = .prepareToPlay
        }
    }
}

extension AudioRecordViewController: BookmarkTableViewDelegate, UITableViewDataSource, UITableViewDelegate {

    func updateBookmarkTableview() {
        annotationTableView.reloadData()
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCellEditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            mediaManager.currentRecording?.annotations!.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

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

            let view = UIView(frame:CGRect())
            let label = UILabel(frame: CGRect())
            label.text = Constants.emptyTableText
            label.textColor = .lightGray
            label.textAlignment = .center
            label.numberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            view.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            label.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            tableView.backgroundView = view
            view.translatesAutoresizingMaskIntoConstraints = false
            view.widthAnchor.constraint(equalTo: tableView.widthAnchor,
                                        constant: -Constants.tableViewInset * 2).isActive = true
            view.leadingAnchor.constraint(equalTo: tableView.leadingAnchor,
                                          constant: Constants.tableViewInset).isActive = true
            view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor,
                                           constant: -Constants.tableViewInset).isActive = true
            view.topAnchor.constraint(equalTo: tableView.topAnchor).isActive = true
            view.bottomAnchor.constraint(equalTo: tableView.topAnchor,
                                         constant: Constants.viewSize).isActive = true
            return 1
        }
        if count > 0 {
            tableView.isScrollEnabled = true
            tableView.backgroundView = nil
            return 1
        }
        return 1
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

                scrubSlider.setValue(Float(bookmark.timeStamp), animated: false)
                switch stateManager.currentState {
                case .playing, .playingPaused, .playingStopped:
                    mediaManager.skipTo(timeInterval: bookmark.timeStamp)
                case .readyToPlay:
                    mediaManager.playAudio()
                    mediaManager.skipTo(timeInterval: bookmark.timeStamp)
                default:
                    return
            }
            if timer == nil { updateTimerDependentUI() }
        }
    }
} // swiftlint:disable:this file_length
