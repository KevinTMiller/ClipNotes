//
//  AVNManager.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/15/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import UIKit
import Disk
import MobileCoreServices

struct Folder: Codable  {
    var userTitle: String
    var systemID: String
    var folderID: String?

}

class AVNManager: NSObject {
    
    static let sharedInstance = AVNManager()
    
    // TODO: Make these strings into constants

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
    
    func changeFolderof(sourceItemID: String , toFolder: String) {
        // Find the item that was the source of the drag and then change
        // its folder ID to the drag destination
        
        if let fileIndex = recordingArray.index(where: {$0.fileName == sourceItemID}) {
            recordingArray[fileIndex].folderID = toFolder
        }
        if let folderIndex = folderList.index(where: {$0.systemID == sourceItemID}) {
            folderList[folderIndex].folderID = toFolder
        }
    }
    
    func addFolder(title: String) {
        let folder = Folder(userTitle: title, systemID: String.uniqueFileName(suffix: nil), folderID: nil)
        folderList.append(folder)
        saveFiles()
    }
    
    func loadFiles() {
        do {
            try recordingArray = Disk.retrieve("recordings.json", from: .documents, as: [AnnotatedRecording].self)
            try folderList = Disk.retrieve("folders.json", from: .documents, as: [Folder].self)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    // Mark: Drag and DeathDrop
    
    func canHandle(_ session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: String.self)
    }
    
    func dragItems(for indexPath: IndexPath) -> [UIDragItem] {
        
        var data: Data?
        if let file = filesAndFolders[indexPath.row] as? AnnotatedRecording {
            data = file.fileName.data(using: .utf8)
        } else {
            let folder = filesAndFolders[indexPath.row] as! Folder
            data = folder.systemID.data(using: .utf8)
        }
        
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
                try Disk.save(self.recordingArray, to: .documents, as: "recordings.json")
                try Disk.save(self.folderList, to: .documents, as: "folders.json")
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
}

