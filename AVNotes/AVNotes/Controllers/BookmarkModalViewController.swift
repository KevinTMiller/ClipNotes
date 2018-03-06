//
//  BookmarkModalViewController.swift
//  AVNotes
//
//  Created by Kevin Miller on 2/12/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit

enum BookmarkType {
    case edit
    case create
}

class BookmarkModalViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    enum Constants {
        static let bookmark = "Bookmark"
        static let editBookmark = "Edit Bookmark"
        static let newBookmark = "New Bookmark"
        static let placeholder = "Long press to edit this bookmark's text."
    }

    @IBAction func doneButtonDidTouch(_ sender: UIButton) {

        switch bookmarkType {
        case .create:
            createBookmark()
        case .edit:
            editBookmark()
        }
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }

    @IBAction func cancelButtonDidTouch(_ sender: UIButton) {
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }

    @IBOutlet private weak var bookmarkView: UIView!
    @IBOutlet private weak var doneButton: UIButton!
    @IBOutlet private weak var bookmarkTitleTextField: UITextField!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var bookmarkModalTitle: UILabel!
    @IBOutlet private weak var bookmarkTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        bookmarkTitleTextField.delegate = self
        bookmarkTextView.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        populateUI()
    }

    var bookmarkTimeStamp = TimeInterval()
    var bookmarkType: BookmarkType = .create
    var currentBookmark: Bookmark?
    var currentBookmarkIndexPath: IndexPath?
    
    private var mediaManager = AudioManager.sharedInstance

    private func populateUI() {
        switch bookmarkType {
        case .create:
            populateFromCurrentRecording()
        case .edit:
            populateFromBookmark()
        }
    }
    
    @objc
    func handleTap(sender: UITapGestureRecognizer) {
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }

    private func populateFromCurrentRecording() {
        if let currentRecording = mediaManager.currentRecording,
            let timeString = mediaManager.currentTimeString {
            let timeStamp = mediaManager.currentTimeInterval
            let bookmarkNumber = String((currentRecording.annotations?.count ?? 0) + 1)
            
            bookmarkTimeStamp = timeStamp
            bookmarkModalTitle.text = Constants.newBookmark + "\(timeString)"
            bookmarkTitleTextField.text = Constants.bookmark + "\(bookmarkNumber)"
            bookmarkTextView.text = ""
        }
    }

    private func populateFromBookmark() {
        if let indexPath = currentBookmarkIndexPath,
            let bookmark = mediaManager.currentRecording?.annotations?[indexPath.row] {
            
            bookmarkModalTitle.text = Constants.editBookmark
            bookmarkTitleTextField.text = bookmark.title
            bookmarkTextView.text = bookmark.noteText
        }
    }

    private func editBookmark() {
        guard let indexPath = currentBookmarkIndexPath else { return }
        let title = bookmarkTitleTextField.text ?? Constants.bookmark
        let text = bookmarkTextView.text ?? ""
      mediaManager.editBookmark(indexPath: indexPath, title: title, text: text)
    }

    private func createBookmark() {
        let title = bookmarkTitleTextField.text ?? Constants.newBookmark
        let text =
        bookmarkTextView.text == "" ? Constants.placeholder : bookmarkTextView.text
        mediaManager.addAnnotation(title: title, text: text!, timestamp: bookmarkTimeStamp)
    }

    @objc
    func keyboardWillShow(notification: Notification) {
        if let keyboardSize =
            (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue,
            view.frame.origin.y == 0 {
            view.frame.origin.y -= keyboardSize.height / 2
        }
    }

    @objc
    func keyboardWillHide(notification: Notification) {
        if let keyboardSize =
            (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue,
            view.frame.origin.y != 0 {
            view.frame.origin.y += keyboardSize.height / 2
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {

        if currentBookmark != nil {
            currentBookmark!.noteText = textView.text
        }

        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
