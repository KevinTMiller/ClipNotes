//
//  AudioRecordViewController.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/5/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//

import UIKit

class AudioRecordViewController: UIViewController {

    @IBOutlet weak var waveformView: UIView!
    @IBOutlet weak var tempWaveformLabel: UILabel!
    @IBOutlet weak var stopWatchLabel: UILabel!
    @IBOutlet weak var recordingTitleLabel: UILabel!
    @IBOutlet weak var recordingDateLabel: UILabel!
    @IBOutlet weak var annotationTableView: UITableView!
    
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
    }
    @IBAction func recordButtonPressed(_ sender: UIButton) {
    }
    @IBAction func addButtonPressed(_ sender: UIButton) {
    }
    
    // MARK: Model control
    
    func startRecording() {
        
    }
    
    func stopRecording() {
        
    }
    
    func addAnnotation(at timestamp: Double) {
        
    }
    
    func getCurrentTimeStamp() -> Double {
    
        return 0.0
    }
    
    // MARK: Lifecycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}
