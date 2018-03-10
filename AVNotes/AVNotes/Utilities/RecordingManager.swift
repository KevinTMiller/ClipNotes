//
//  RecordingManager.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/15/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import Disk
import MobileCoreServices
import UIKit

struct Folder: Codable {
    var systemID: String
    var userTitle: String
}

class RecordingManager: NSObject {

    enum Constants {
        static let folderJSON = "folders.json"
        static let recordingJSON = "recordings.json"
    }

    static let sharedInstance = RecordingManager()

    // Public Vars
    var folderList = [Folder]() {
        didSet {
            notifyUpdate()
        }
    }
    var currentRecording: AnnotatedRecording?
    var recordingArray = [AnnotatedRecording]() {
        didSet {
            notifyUpdate()
        }
    }
    var filesAndFolders: [Any] {
        let uncategorized = (recordingArray.filter { $0.folderID == "" }) as [Any]
        let folders = folderList as [Any]
        return folders + uncategorized
    }

    private func notifyUpdate() {
        NotificationCenter.default.post(name: .annotationsDidUpdate, object: nil)
         NotificationCenter.default.post(name: .modelDidUpdate, object: nil)
    }

    func changeFolderof(sourceItemID: String, toFolder: String) {
        // Find the item that was the source of the drag and then change
        // its folder ID to the drag destination

        if let fileIndex = recordingArray.index(where: { $0.fileName == sourceItemID }) {
            recordingArray[fileIndex].folderID = toFolder
        }
    }

    func editTitleOf(uniqueID: String, newTitle: String) {
        if let folderIndex = folderList.index(where: { $0.systemID == uniqueID }) {
            folderList[folderIndex].userTitle = newTitle
        }
        if let recordingIndex = recordingArray.index(where: { $0.fileName == uniqueID }) {
            recordingArray[recordingIndex].userTitle = newTitle
        }
        saveFiles()
    }

    func addFolder(title: String) {
        let folder = Folder(systemID: String.uniqueFileName(suffix: nil), userTitle: title)
        folderList.append(folder)
        saveFiles()
    }

    func deleteFolder(identifier: String) {
        if let index = folderList.index(where: { $0.systemID == identifier }) {
            folderList.remove(at: index)
        }

        let files = recordingArray.filter { $0.folderID == identifier }
        for file in files {
            if let index = recordingArray.index(where: { $0.fileName == file.fileName }) {
                recordingArray.remove(at: index)
            }
        }
        saveFiles()
    }

    func deleteFile(identifier: String) {
        if let index = recordingArray.index(where: { $0.fileName == identifier }) {
            recordingArray.remove(at: index)
            saveFiles()
        }
    }

    func loadFiles() {
        do {
            try recordingArray = Disk.retrieve(Constants.recordingJSON,
                                               from: .documents,
                                               as: [AnnotatedRecording].self)
            try folderList = Disk.retrieve(Constants.folderJSON,
                                           from: .documents,
                                           as: [Folder].self)
        } catch let error {
            print(error.localizedDescription)
        }
    }

    // MARK: Drag and DeathDrop

    func canHandle(_ session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: String.self)
    }

    func dragItems(for indexPath: IndexPath) -> [UIDragItem] {
        guard let file = filesAndFolders[indexPath.row] as? AnnotatedRecording else {
            return []
        }
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

    func saveFiles() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try Disk.save(self.recordingArray, to: .documents, as: Constants.recordingJSON)
                try Disk.save(self.folderList, to: .documents, as: Constants.folderJSON)
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
}
