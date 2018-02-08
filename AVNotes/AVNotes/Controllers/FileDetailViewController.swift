//
//  FileDetailViewController.swift
//  AVNotes
//
//  Created by Kevin Miller on 1/19/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

class FileDetailViewController: UIViewController{
    
    let cellIdentifier = "fileViewCell"
    let unwindSegue = "unwindToAudioRecord"
    
    var folder: Folder!
    var recordings: [AnnotatedRecording]!
    var mediaManager = AudioPlayerRecorder.sharedInstance
    
    @IBAction func addDidTouch(_ sender: UIBarButtonItem) {
        mediaManager.currentMode = .record
        navigationController?.popToRootViewController(animated: true)
    }
    @IBAction func doneDidTouch(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var fileDetailTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension FileDetailViewController : UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordings.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        mediaManager.switchToPlay(file: recordings[indexPath.row])
        navigationController?.popToRootViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? FileViewCell {
            cell.populateSelfFrom(recording: recordings[indexPath.row])
            return cell
        }
        return cell
    }
    
}
