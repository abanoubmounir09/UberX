//
//  Alertable.swift
//  UberX
//
//  Created by pop on 7/6/20.
//  Copyright © 2020 pop. All rights reserved.
//

import UIKit

protocol Alertable{
    
}

extension Alertable where Self:UIViewController{
    func showAlert(_ msg:String){
        let AlertController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        AlertController.addAction(action)
        present(AlertController, animated: true, completion: nil)
    }
}
