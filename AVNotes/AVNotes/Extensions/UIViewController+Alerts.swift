//
//  UIViewController+Alerts.swift
//  AVNotes
//
//  Created by Kevin Miller on 1/17/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.


import UIKit

extension UIViewController {
    
    func presentBookmarkDialog(title: String, message: String){
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
        self.present(alertController, animated: true) {
            
        }
    }
}
