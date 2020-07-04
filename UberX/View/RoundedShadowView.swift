//
//  RoundedShadowView.swift
//  UberX
//
//  Created by pop on 6/23/20.
//  Copyright © 2020 pop. All rights reserved.
//

import UIKit

class RoundedShadowView: UIView {

    override func awakeFromNib() {
        setupView()
        
    }
    
    func setupView(){
        
        self.layer.cornerRadius  = 5.0
        self.layer.shadowOpacity  = 0.3
        self.layer.shadowRadius = 5
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 5)
        
    }

}

class rondedView:UIView{
    
    @IBInspectable var borderColor:UIColor?{
    didSet{
        setupView()
      }
    }
    override func awakeFromNib() {
        setupView()
    }
    
    func setupView(){
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.borderWidth = 1.5
        self.clipsToBounds = true
        self.layer.borderColor = borderColor?.cgColor
    }
    
}


class RoundedButton:UIButton{
    var originalSize:CGRect?
    override func awakeFromNib() {
        setupBtn()
    }
    
    func setupBtn(){
        originalSize = self.frame
        self.layer.cornerRadius  = 5.0
        self.layer.shadowOpacity  = 0.3
        self.layer.shadowRadius = 10
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowOffset = CGSize.zero
    }
    
    func animateButton(shouldLoad : Bool, withmessage message:String?){
        let spinner = UIActivityIndicatorView()
        spinner.style = .whiteLarge
        spinner.color = UIColor.darkGray
        spinner.alpha = 0.0
        spinner.hidesWhenStopped = true
        spinner.tag = 5
        if shouldLoad{
            self.setTitle("", for: .normal)
            UIView.animate(withDuration: 0.2, animations: {
                self.layer.cornerRadius = self.frame.height / 2
                self.frame = CGRect(x: self.frame.midX - (self.frame.height / 2), y: self.frame.origin.y, width: self.frame.height  , height: self.frame.height )
            }) { (finished) in
                if finished == true{
                    self.addSubview(spinner)
                     spinner.startAnimating()
                     spinner.center = CGPoint(x: self.frame.width / 2 + 1, y: self.frame.width / 2 + 1)
                    spinner.fadeTo(alphavalue: 1.0, duration: 0.2)
//                    UIView.animate(withDuration: 0.2, animations: {
//                       spinner.alpha = 1.0
//                    })
                }
            }
                self.isUserInteractionEnabled = false
        }else{
            self.isUserInteractionEnabled = true
            for subview in self.subviews{
                if subview.tag == 5 {
                    subview.removeFromSuperview()
                }
            }
            UIView.animate(withDuration: 0.5) {
                self.layer.cornerRadius = 5.0
                self.frame = self.originalSize!
                self.setTitle(message, for: .normal)
        }
        
        }
    }
}
