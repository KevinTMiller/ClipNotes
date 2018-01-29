//
//  FileViewController.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/5/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import UIKit


class FileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

   
    @IBAction func doneButtonDidTouch(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBOutlet weak var fileTableView: UITableView!
    private let cellIdentifier = "fileViewCell"
    // MARK: Private Vars
    
    private let fileManager = AVNManager.sharedInstance
    private let mediaManager = AudioPlayerRecorder.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateTableView), name: .annotationsDidUpdate, object: nil)
    }
    
    // MARK: Segue prep
    
    // Check to see if
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    // MARK: Private funcs
    @objc private func updateTableView() {
        fileTableView.reloadData()
    }
    
    // MARK: Tableview Delegate / Datasource
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        mediaManager.currentRecording = fileManager.recordingArray[indexPath.row]
        mediaManager.currentMode = .play
        dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileManager.recordingArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < fileManager.recordingArray.count else {fatalError("Index row exceeds array bounds")}
        let recording = fileManager.recordingArray[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! FileViewCell
        cell.titleLabel.text = recording.userTitle
        let bookmarkCount = recording.annotations?.count ?? 0
        cell.bookmarkLabel.text = "\(bookmarkCount) Bookmarks"
        cell.durationLabel.text = String.stringFrom(timeInterval: recording.duration)
        cell.dateLabel.text = DateFormatter.localizedString(from: recording.date, dateStyle: .short, timeStyle: .none)
        
        return cell
    }
}
