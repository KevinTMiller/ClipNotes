//
//  String+UniqueFileName.swift
//  AVNotes
//
//  Created by Kevin Miller on 1/1/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import Foundation

extension String {
    static func uniqueFileName(suffix: String?) -> String {
        var string = UUID().uuidString
        if let suffix = suffix {
            string.append(suffix)
        }
        return string
    }
}
