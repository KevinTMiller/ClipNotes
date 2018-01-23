//
//  VideoRecordViewController.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/5/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import UIKit
import AVKit
import MobileCoreServices

class VideoRecordViewController: UIViewController {

    //TODO: make custom tableviewcells
    let cellIdentifer = "videoCell"
    
    @IBAction func doneButtonDidTouch(_ sender: UIButton) {
    }
    
    @IBAction func addButtonDidTouch(_ sender: UIButton) {
    }
    @IBAction func recordButtonDidTouch(_ sender: UIButton) {
    }
    @IBOutlet var accessoryView: UIView!
    enum CameraSelection {
        case rear
        case front
    }
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var videoTableView: UITableView!
    
    private let session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput!
    private var movieFileOutput: AVCaptureMovieFileOutput?
    private var videoCaptureDevice: AVCaptureDevice?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var deviceOrientation: UIDeviceOrientation?
    private var imagePickerController: UIImagePickerController?
    private var defaults = UserDefaults.standard
    private var manager = AVNManager.sharedInstance
    
    private func initializeCaptureSession() {
        AVCaptureDevice.requestAccess(for: .video) { (authorized) in
            if authorized {
                print("Video capture authorized")
            } else {
                print("Video capture not authorized")
                // TODO: Add error to user here
            }
        }
    }
    
    private func initializeCaptureDevice () {
        
        videoCaptureDevice = AVCaptureDevice.default(for: .video)
        
        if let device = videoCaptureDevice {
            do {
                // Prevents other apps from changing device configuration
                try device.lockForConfiguration()
                
                // Auto Focus settings
                device.focusMode = .continuousAutoFocus
                if device.isSmoothAutoFocusSupported {
                    device.isSmoothAutoFocusEnabled = true
                }
                device.exposureMode = .continuousAutoExposure
                device.whiteBalanceMode = .continuousAutoWhiteBalance
                device.automaticallyEnablesLowLightBoostWhenAvailable = true
                device.unlockForConfiguration()
            } catch {
                print("Unable to configure device")
            }
        }
    }
    private func initializeCaptureDeviceInput () {
        
    }
    private func launchVideoCamera() {
    
    
        initializeCaptureSession()
        imagePickerController = UIImagePickerController()
        imagePickerController?.sourceType = .camera
        imagePickerController?.mediaTypes = [kUTTypeMovie as String]
        imagePickerController?.allowsEditing = false
        imagePickerController?.delegate = self
        imagePickerController?.isToolbarHidden = true
        imagePickerController?.showsCameraControls = true
//        self.view.addSubview((imagePickerController!.view)!)
        present(imagePickerController!, animated: true, completion: nil)
        

    }
    @objc private func addAnnotation() {
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        launchVideoCamera()
        NotificationCenter.default.addObserver(self, selector: #selector(updateTableView), name: .annotationsDidUpdate, object: nil)
        
        
    }
    @objc private func updateTableView() {
        videoTableView.reloadData()
    }
    @objc func video(videoPath: String, didFinishSavingWithError error: NSError?, contextInfo info: AnyObject) {
        var title = "Success"
        var message = "Video was saved"
        if let _ = error {
            title = "Error"
            message = "Video failed to save"
        }
    
    // TODO: put this in its own func
    let lastVideo = defaults.value(forKey: "lastVideo") as? Int ?? 1
    let userTitle = "Video \(lastVideo)"
    let recording = AnnotatedRecording(timeStamp: nil,
                                       userTitle: userTitle,
                                       fileName: videoPath,
                                       annotations: nil,
                                       mediaType: .video)
    manager.recordingArray.append(recording)
    
    
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

extension VideoRecordViewController : UITableViewDelegate {
    
}
extension VideoRecordViewController : UITableViewDataSource {
   
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return manager.recordingArray.count
    }
    // TODO: I've written this code 3x, any way to fix?
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < manager.recordingArray.count else {fatalError("Index row exceeds array bounds")}
        let recording = manager.recordingArray[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifer)!
        cell.textLabel?.text = recording.userTitle
        cell.detailTextLabel?.text = recording.fileName
        return cell
    }
    
}

// MARK: UIImagePickerControllerDelegate
extension VideoRecordViewController : UIImagePickerControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        dismiss(animated: true, completion: nil)
        if mediaType == kUTTypeMovie as String {
            let path = (info[UIImagePickerControllerMediaURL] as! URL).path
            if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path){
                UISaveVideoAtPathToSavedPhotosAlbum(path, self, #selector(video(videoPath:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }
}
// MARK: UINavigationControllerDelegate
extension VideoRecordViewController : UINavigationControllerDelegate {
    
}
