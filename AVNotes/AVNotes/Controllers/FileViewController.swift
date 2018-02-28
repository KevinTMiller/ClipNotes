//
//  FileViewController.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/5/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import UIKit

class FileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let segueIdentifier = "toFileDetail"

    private enum Constants {
        static let fileCell = "fileViewCell"
        static let folderCell = "folderCell"
    }

    private enum AlertConstants {
        static let enterName = "Enter name for Folder"
        static let newFolder = "New Folder"
        static let delete = "Delete"
        static let areYouSure =
        "Are you sure you wish to delete this item? This action cannot be undone."
        static let editTitle = "Edit Recording Title"
        static let editTitleMessage = "Enter the new title below"
        static let editFolder = "Edit Folder Name"
        static let editFolderMessage = "Enter new folder name below"
    }

    private let fileManager = RecordingManager.sharedInstance
    private let mediaManager = AudioManager.sharedInstance

    @IBAction func newFolderDidTouch(_ sender: UIBarButtonItem) {
        self.presentAlertWith(title: AlertConstants.newFolder, message: AlertConstants.enterName,
                              placeholder: AlertConstants.newFolder) { [weak self] text in
            var userTitle = text
            if text == "" { userTitle = AlertConstants.newFolder }
            self?.fileManager.addFolder(title: userTitle)
        }
    }

    @IBOutlet private weak var fileTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        definesPresentationContext = true
        fileTableView.dragDelegate = self
        fileTableView.dropDelegate = self
        fileTableView.dragInteractionEnabled = true

        NotificationCenter.default.addObserver(self, selector: #selector(updateTableView),
                                               name: .annotationsDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateTableView),
                                               name: .modelDidUpdate, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = .default
        setNeedsStatusBarAppearanceUpdate()
        updateTableView()
    }

    // MARK: Segue prep
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueIdentifier,
            let destination = segue.destination as? FileDetailViewController,
            let folderCell = sender as? FolderTableViewCell,
            let indexPath = fileTableView.indexPath(for: folderCell),
            let folder = fileManager.filesAndFolders[indexPath.row] as? Folder {
            destination.folder = folder
        }
    }

    // MARK: Private funcs
    @objc
    private func updateTableView() {
        fileTableView.reloadData()
    }

    @objc
    private func editFileorFolder(sender: UILongPressGestureRecognizer) {
        presentAlertWith(title: "Edit", message: "message", placeholder: "Placeholder") { text in
         print("Edit to \(text)")
            // TODO: implement editing folder names and file names
        }
    }

    // MARK: Tableview Delegate / Datasource
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView,
                   editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        let delete = UITableViewRowAction(style: .destructive,
                                          title: AlertConstants.delete) { [weak self] action, indexPath in
            self?.presentAlert(title: AlertConstants.delete, message: AlertConstants.areYouSure)
            // TODO: Implement method to delete file or folder
        }
        let edit = UITableViewRowAction(style: .normal, title: "Edit") { [weak self] _, indexPath in
            var title = String()
            var message = String()
            var placeholder = String()
            var uniqueID = String()

            if let currentRecording =
                self?.fileManager.filesAndFolders[indexPath.row] as? AnnotatedRecording {
                title = AlertConstants.editTitle
                message = AlertConstants.editTitleMessage
                placeholder = currentRecording.userTitle
                uniqueID = currentRecording.fileName
            }
            if let currentFolder =
                self?.fileManager.filesAndFolders[indexPath.row] as? Folder {
                title = AlertConstants.editFolder
                message = AlertConstants.editFolderMessage
                placeholder = currentFolder.userTitle
                uniqueID = currentFolder.systemID
            }
            self?.presentAlertWith(title: title,
                                   message: message,
                                   placeholder: placeholder,
                                   completion: { [weak self] text in
                self?.fileManager.editTitleOf(uniqueID: uniqueID, newTitle: text)
            })
        }
        return [delete, edit]
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selection = fileManager.filesAndFolders[indexPath.row]

        if let recording = selection as? AnnotatedRecording {
            switch mediaManager.currentMode {
            case .record:
                mediaManager.stopRecordingAudio()
            case .play:
                mediaManager.stopRecordingAudio()
            }
            mediaManager.switchToPlay(file: recording)
            navigationController?.popToRootViewController(animated: true)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileManager.filesAndFolders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = fileManager.filesAndFolders
        guard indexPath.row <= data.count else { fatalError("Index path exceeds bounds") }

        if let folder = data[indexPath.row] as? Folder,
            let cell =
            tableView.dequeueReusableCell(withIdentifier: Constants.folderCell) as? FolderTableViewCell {
            cell.populateSelf(folder: folder)
            return cell
        }
        if let file = data[indexPath.row] as? AnnotatedRecording,
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.fileCell) as? FileViewCell {
            cell.populateSelfFrom(recording: file)
            return cell
        }
        return tableView.dequeueReusableCell(withIdentifier: Constants.folderCell)!
    }

    // Files and Folder is a get only calculated property - must move the objects
    // in their own arrays. If an annotated recording, must find the real index
    // as the files and folders array only shows uncategorized files
    // Can't have one array because ANY is not Codable and
    // would be difficult to persist to disk as JSON using DISK

    func tableView(_ tableView: UITableView,
                   moveRowAt sourceIndexPath: IndexPath,
                   to destinationIndexPath: IndexPath) {
        let itemToMove = fileManager.filesAndFolders[sourceIndexPath.row]
        let itemToReplace = fileManager.filesAndFolders[destinationIndexPath.row]

        if let folder = itemToMove as? Folder {
            if destinationIndexPath.row >= fileManager.folderList.count {
                fileManager.folderList.remove(at: sourceIndexPath.row)
                fileManager.folderList.insert(folder, at: fileManager.folderList.endIndex)
            } else {
                fileManager.folderList.remove(at: sourceIndexPath.row)
                fileManager.folderList.insert(folder, at: destinationIndexPath.row)
            }
        }
        if let file = itemToMove as? AnnotatedRecording,
            let destination = itemToReplace as? AnnotatedRecording,
            let adjustedSourceIndex =
            fileManager.recordingArray.index(where: { $0.fileName == file.fileName }),
            let adjustedDestinationIndex =
            fileManager.recordingArray.index(where: { $0.fileName == destination.fileName }) {
            let removed = fileManager.recordingArray.remove(at: adjustedSourceIndex)
            fileManager.recordingArray.insert(removed, at: adjustedDestinationIndex)
        }
    }
}
extension FileViewController: UITableViewDragDelegate, UITableViewDropDelegate {

    func tableView(_ tableView: UITableView, dragSessionAllowsMoveOperation session: UIDragSession) -> Bool {
        return true
    }

    // When returning [], will still allow you to reorder
    func tableView(_ tableView: UITableView,
                   itemsForBeginning session: UIDragSession,
                   at indexPath: IndexPath) -> [UIDragItem] {
        if fileManager.filesAndFolders[indexPath.row] is Folder { return [] }
        return fileManager.dragItems(for: indexPath)
    }

    func tableView(_ tableView: UITableView,
                   dropSessionDidUpdate session: UIDropSession,
                   withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        if tableView.hasActiveDrag {
            if session.items.count > 1 {
                return UITableViewDropProposal(operation: .cancel)
            } else {
                if let destination = destinationIndexPath,
                    (fileManager.filesAndFolders[destination.row]) is Folder {
                    return UITableViewDropProposal(operation: .copy, intent: .insertIntoDestinationIndexPath)
                }
                return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            }
        } else {
            if let destination = destinationIndexPath,
                (fileManager.filesAndFolders[destination.row]) is Folder {
                return UITableViewDropProposal(operation: .copy, intent: .insertIntoDestinationIndexPath)
            }
        }
        return UITableViewDropProposal(operation: .cancel)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        let destinationIndexPath: IndexPath

        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let section = tableView.numberOfSections - 1
            let row = tableView.numberOfRows(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        coordinator.session.loadObjects(ofClass: NSString.self) { items in
            guard let dragStringItem = items[0] as? String else { return }
            var desiredFolderID: String

            if let folder = self.fileManager.filesAndFolders[destinationIndexPath.row] as? Folder {
                desiredFolderID = folder.systemID
            } else {
                desiredFolderID = ""
            }
            self.fileManager.changeFolderof(sourceItemID: dragStringItem, toFolder: desiredFolderID)
            self.fileManager.saveFiles()
            tableView.reloadData()
        }
    }

    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return fileManager.canHandle(session)
    }
}
