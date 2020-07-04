//
//  RoundedTxtF.swift
//  UberX
//
//  Created by pop on 6/24/20.
//  Copyright © 2020 pop. All rights reserved.
//

import UIKit

class RoundedTxtF: UITextField {
    var textRectOffset:CGFloat = 20
    
    override func awakeFromNib() {
        setupView()
    }
    
    func setupView(){
        self.layer.cornerRadius = 8 //self.frame.height / 2
    }

//    override func textRect(forBounds bounds: CGRect) -> CGRect {
//        return CGRect(x: 0 + textRectOffset, y: 0 + (textRectOffset / 2), width: self.frame.width - textRectOffset, height: self.frame.height + 15   )
//    }
//
//    override func editingRect(forBounds bounds: CGRect) -> CGRect {
//        return CGRect(x: 0 + textRectOffset, y: 0 + (textRectOffset / 2), width: self.frame.width - textRectOffset, height: self.frame.height - 15 )
//    }
    
}
