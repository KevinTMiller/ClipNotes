//
//  AVNAnnotation.swift
//  AVNotes
//
//  Created by Kevin Miller on 12/15/17.
//  Copyright © 2017 Kevin Miller. All rights reserved.
//


// This is the annotation object that should contain a string and a timestamp of where it is in the recoding. Should be a struct?

struct AVNAnnotation : Timestampable {
    var timeStamp: Double?
    var noteText: String
}
