//
//  CustomModalPresentationManager.swift
//  AVNotes
//
//  Created by Kevin Miller on 2/14/18.
//  Copyright © 2018 Kevin Miller. All rights reserved.
//

import UIKit


class CustomModalPresentationManager: NSObject {
 

}

extension CustomModalPresentationManager : UIViewControllerTransitioningDelegate {
 
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
    
        let presentationController = ModalPresentationController(presentedViewController: presented, presenting: presenting)
        
        return presentationController
    }
}

