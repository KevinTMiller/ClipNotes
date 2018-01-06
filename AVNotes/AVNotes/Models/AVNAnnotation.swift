//
//  AVNAnnotation.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/15/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//


struct AVNAnnotation : Timestampable , Codable {
    var timeStamp: Double?
    var noteText: String
}
