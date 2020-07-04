//
//  UIVewiExt.swift
//  UberX
//
//  Created by pop on 6/24/20.
//  Copyright © 2020 pop. All rights reserved.
//

import UIKit

extension UIView{
    
    func fadeTo(alphavalue : CGFloat, duration:TimeInterval){
        UIView.animate(withDuration: duration) {
            self.alpha = alphavalue
        }
    }
    
    
    func bindToKeyBoard(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChnge(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc func keyboardWillChnge(_ aNotification:NSNotification){
        let duration = aNotification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        let curv = aNotification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt
    let curvFram = (aNotification.userInfo![UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let targetFram = (aNotification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let deltay = targetFram.origin.y - curvFram.origin.y
        UIView.animateKeyframes(withDuration: duration, delay: 0.0, options: UIView.KeyframeAnimationOptions(rawValue: curv), animations: {
            self.frame.origin.y += deltay
        }, completion: nil)
    }
}
