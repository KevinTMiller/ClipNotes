//
//  FileViewController.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/5/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import UIKit


class FileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? FileDetailViewController,
            let indexPath = fileTableView.indexPathForSelectedRow {
            destination.recording = fileManager.recordingArray[indexPath.row]
        }
    }
    // MARK: Private funcs
    @objc private func updateTableView() {
        fileTableView.reloadData()
    }
    
    // MARK: Tableview Delegate / Datasource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileManager.recordingArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < fileManager.recordingArray.count else {fatalError("Index row exceeds array bounds")}
        let recording = fileManager.recordingArray[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        cell.textLabel?.text = recording.userTitle
        cell.detailTextLabel?.text = recording.fileName
        return cell
    }
    
}
