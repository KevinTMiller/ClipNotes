//
//  AlertManager.swift
//  AVNotes
//
//  Created by Kevin Miller on 1/17/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

class AlertManager: NSObject {

    static func presentBookmarkDialog(title: String, message: String, sender: UIViewController){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
            // TODO: Handle OK action
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        alertController.addTextField { (textField) in
            textField.placeholder = "Enter bookmark text"
            textField.clearsOnInsertion = true
            textField.autocorrectionType = .default
        }
        
    }
    static func presentAlert(with title: String, message: String) {
        
    }
    
}
