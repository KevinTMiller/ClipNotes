//
//  FileDetailViewController.swift
//  AVNotes
//
//  Created by Kevin Miller on 1/19/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import MobileCoreServices
import UIKit

class FileDetailViewController: UIViewController {
    
    enum Constants {
        static let cellIdentifier = "fileViewCell"
        static let cornerRadius: CGFloat = 8.0
        static let folderCellIdentifier = "folderCell"
        static let folderLabel = "Files"
        static let folderIcon = "⇧"
        static let newRecordingText = "New recording in "
        static let onePixel = 1 / UIScreen.main.scale
        static let unwindSegue = "unwindToAudioRecord"
    }

    @IBOutlet private var newRecordingButton: UIButton!
    var folder: Folder!
    private var recordings: [AnnotatedRecording]! {
        return fileManager.recordingArray.filter({ $0.folderID == folder.systemID })
    }
    
    private lazy var stateManager = StateManager.sharedInstance
    private lazy var audioManager = AudioManager.sharedInstance
    private lazy var fileManager = RecordingManager.sharedInstance
    private weak var modalTransitioningDelegate = CustomModalPresentationManager()
    
    @IBOutlet private weak var fileDetailTableView: UITableView!

    @IBAction func newRecordingDidTouch(_ sender: UIButton) {
        stateManager.currentState = .prepareToRecord
        audioManager.currentRecording?.folderID = folder.systemID
        navigationController?.popToRootViewController(animated: true)
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        newRecordingButton.titleLabel?.text = Constants.newRecordingText + folder.userTitle
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        fileDetailTableView.dragInteractionEnabled = true
        fileDetailTableView.dragDelegate = self
        fileDetailTableView.dropDelegate = self
        newRecordingButton.layer.cornerRadius = Constants.cornerRadius
        newRecordingButton.layer.borderWidth = Constants.onePixel
        newRecordingButton.layer.borderColor = UIColor.darkGray.cgColor
        newRecordingButton.titleLabel?.textAlignment = .center
    }
}

extension FileDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == 0 {
            return false
        }
        return true
    }
    
    func tableView(_ tableView: UITableView,
                   editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive,
                                          title: AlertConstants.delete) { [weak self] _, indexPath in
            self?.confirmDestructiveAlert(title: AlertConstants.delete,
                                          message: AlertConstants.areYouSure,
                                          delete: {
                                            tableView.beginUpdates()
                                            if let file = self?.recordings[indexPath.row - 1] {
                                                self?.fileManager.deleteFile(identifier: file.fileName)
                                            }
                                            tableView.deleteRows(at: [indexPath], with: .automatic)
                                            tableView.endUpdates()
                                            })
        }

        let edit = UITableViewRowAction(style: .normal, title: "Edit") { [weak self] _, indexPath in

            if let currentRecording = self?.recordings[indexPath.row - 1] {
                let title = AlertConstants.editTitle
                let message = AlertConstants.editTitleMessage
                let placeholder = currentRecording.userTitle
                let uniqueID = currentRecording.fileName

                self?.presentAlertWith(title: title,
                                       message: message,
                                       placeholder: placeholder,
                                       completion: { [weak self] text in
                                        self?.fileManager.editTitleOf(uniqueID: uniqueID, newTitle: text)
                                        tableView.reloadRows(at: [indexPath], with: .automatic )
                })
            }
        }
        return [delete, edit]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordings.count + 1
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if indexPath.row == 0 {
            navigationController?.popViewController(animated: true)
        }
        if indexPath.row > 0 {
            audioManager.switchToPlay(file: recordings[(indexPath.row - 1)])
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.row == 0,
            let cell =
            tableView.dequeueReusableCell(withIdentifier: Constants.folderCellIdentifier)
                as? FolderTableViewCell {
            cell.populateWith(title: Constants.folderLabel, icon: Constants.folderIcon)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier)!

        if indexPath.row > 0 {
            if let cell =
                tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier) as? FileViewCell {
                cell.populateSelfFrom(recording: recordings[indexPath.row - 1])
                return cell
            }
        }
        return cell
    }
}

extension FileDetailViewController: UITableViewDragDelegate, UITableViewDropDelegate {

    func tableView(_ tableView: UITableView,
                   itemsForBeginning session: UIDragSession,
                   at indexPath: IndexPath) -> [UIDragItem] {
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
            guard let dragStringItem = items[0] as? String else { return }
            if coordinator.destinationIndexPath?.row == 0 {
                self.fileManager.changeFolderof(sourceItemID: dragStringItem, toFolder: "")
                tableView.reloadData()
            }
        }
    }
    // Cannot implement move operation because the recordings in the vc are filtered from the model.
    // May need to refactor this in the future. For now will just sort by date
    func tableView(_ tableView: UITableView, dragSessionAllowsMoveOperation session: UIDragSession) -> Bool {
        return false
    }

    func tableView(_ tableView: UITableView,
                   dropSessionDidUpdate session: UIDropSession,
                   withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {

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
