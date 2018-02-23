//
//  FileDetailViewController.swift
//  AVNotes
//
//  Created by Kevin Miller on 1/19/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit
import MobileCoreServices

class FileDetailViewController: UIViewController{
    
    let cellIdentifier = "fileViewCell"
    let folderCellIdentifier = "folderCell"
    let unwindSegue = "unwindToAudioRecord"
    
    var folder: Folder!
    var recordings: [AnnotatedRecording]! {
        return fileManager.recordingArray.filter({$0.folderID == folder.systemID})
    }
    var mediaManager = AudioPlayerRecorder.sharedInstance
    var fileManager = AVNManager.sharedInstance
    var modalTransitioningDelegate = CustomModalPresentationManager()
    
    @IBOutlet weak var fileDetailTableView: UITableView!
    @IBAction func addDidTouch(_ sender: UIBarButtonItem) {
        mediaManager.currentMode = .record
        mediaManager.currentRecording?.folderID = folder.systemID
        navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func doneDidTouch(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fileDetailTableView.dragInteractionEnabled = true
        fileDetailTableView.dragDelegate = self
        fileDetailTableView.dropDelegate = self
    }
}

extension FileDetailViewController : UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordings.count + 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        mediaManager.switchToPlay(file: recordings[indexPath.row])
        navigationController?.popToRootViewController(animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0,
            let cell = tableView.dequeueReusableCell(withIdentifier: folderCellIdentifier) as? FolderTableViewCell {
            cell.fileCountLabel.text = "⇧"
            cell.folderTitleLabel.text = "Files"
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        
        if indexPath.row > 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? FileViewCell {
                cell.populateSelfFrom(recording: recordings[indexPath.row - 1])
                return cell
            }
        }
        return cell
    }
}
extension FileDetailViewController : UITableViewDragDelegate, UITableViewDropDelegate {
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        guard indexPath.row > 0 else { return [] }
        
        let file = recordings[indexPath.row - 1]
        let data = file.fileName.data(using: .utf8)
        
        let itemProvider = NSItemProvider()
        itemProvider.registerDataRepresentation(forTypeIdentifier: kUTTypePlainText as String,
                                                visibility: .all,
                                                loadHandler: { completion in
                                                    completion(data, nil)
                                                    return nil
        })
        let dragItem = UIDragItem(itemProvider: itemProvider)
        return [dragItem]
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        
        coordinator.session.loadObjects(ofClass: NSString.self) { items in
            
            let dragStringItem = items[0] as! String
            
            self.fileManager.changeFolderof(sourceItemID: dragStringItem , toFolder: "")
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, dragSessionAllowsMoveOperation session: UIDragSession) -> Bool {
        return false
    }
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        
        if tableView.hasActiveDrag {
            if session.items.count > 1 {
                return UITableViewDropProposal(operation: .cancel)
            } else {
                if let destination = destinationIndexPath?.row,
                    destination == 0 {
                    return UITableViewDropProposal(operation: .copy, intent: .insertIntoDestinationIndexPath)
                }
            }
        }
        return UITableViewDropProposal(operation: .cancel)
    }

    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return fileManager.canHandle(session)
    }
}
