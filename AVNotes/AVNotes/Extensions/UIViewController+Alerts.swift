//
//  UIViewController+Alerts.swift
//  AVNotes
//
//  Created by Kevin Miller on 1/17/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import AVKit
import UIKit

extension UIViewController {

    enum Constants {
        static let cancel = "Cancel"
        static let confirm = "OK"
        static let delete = "Delete"
    }

    func presentAlertWith(title: String, message: String,
                          placeholder: String, completion: @escaping (String) -> Void) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: Constants.confirm, style: .default) { _ in
            if let textField = alertController.textFields?[0],
                let text = textField.text {
                completion(text)
            }
        }
        let cancelAction = UIAlertAction(title: Constants.cancel, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        alertController.addTextField { textField in
            textField.placeholder = placeholder
            textField.clearsOnInsertion = true
            textField.autocorrectionType = .default
        }
        self.present(alertController, animated: true)
    }

    func confirmDestructiveAlert(title: String, message: String, delete: @escaping () -> Void ) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: Constants.delete, style: .destructive) { _ in delete() }
        let cancelAction = UIAlertAction(title: Constants.cancel, style: .cancel, handler: nil)
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true)
    }

    func presentAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: Constants.confirm, style: .cancel, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
