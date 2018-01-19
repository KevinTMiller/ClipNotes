//
//  FileDetailViewController.swift
//  AVNotes
//
//  Created by Kevin Miller on 1/19/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

class FileDetailViewController: UIViewController{
    
    let cellIdentifier = "bookmarkCell"
    

    @IBOutlet weak var bookmarkTableView: UITableView!
    
    var recording: AnnotatedRecording?
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
}
extension FileDetailViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Bookmarks"
    }
}

extension FileDetailViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recording?.annotations?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        if let bookmark = recording?.annotations?[indexPath.row] {
            cell.textLabel?.text = bookmark.title
            cell.detailTextLabel?.text = bookmark.noteText
        }
        return cell
    }
    
}
