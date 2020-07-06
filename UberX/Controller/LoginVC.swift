//
//  LoginVC.swift
//  UberX
//
//  Created by pop on 6/24/20.
//  Copyright © 2020 pop. All rights reserved.
//

import UIKit
import Firebase

class LoginVC: UIViewController,UITextFieldDelegate,Alertable {

    //outlets
    @IBOutlet weak var emailField: RoundedTxtF!
    @IBOutlet weak var passwordField: RoundedTxtF!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var authButton: RoundedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       setup()
    }
    
    func setup(){
        emailField.delegate = self
        passwordField.delegate = self
        view.bindToKeyBoard()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handeltapGesture))
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func handeltapGesture(){
        self.view.endEditing(true)
    }
    
    @IBAction func closeBTNPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func authBTNPressed(_ sender: Any) {
        if emailField.text != nil && passwordField.text != nil{
            authButton.animateButton(shouldLoad: true, withmessage: nil)
            self.view.endEditing(true)
            if let email = emailField.text, let password = passwordField.text{
                Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                    if error == nil{
                        if let user = user{
                            // login user or driver
                            if self.segmentControl.selectedSegmentIndex == 0{
                                let userData = ["provider":user.user.providerID] as? [String:Any]
                                DataService.instance.createFirebaseUser(uid: user.user.uid, userData: userData!, isDriver: false)
                            }else{// driver
                                let userData = ["provider":user.user.providerID,"userIsDriver":true,"isPickupModeEnabled":false,"driverIsOnTrip":false] as? [String:Any]
                                DataService.instance.createFirebaseUser(uid: user.user.uid, userData: userData!, isDriver: true)
                            }
                        }
                        print("successfulf login")
                        self.dismiss(animated: true, completion: nil)
                    }else{
                        //get error and create acount
                        if let errorcode = AuthErrorCode(rawValue: error!._code){
                            switch errorcode{
                            case .invalidEmail:
                                self.showAlert("invalid  mail")
                                
                            default:
                                self.showAlert("network issues")
                               
                            }
                        }
                        // create
                        
                        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                            if error != nil{
                                if let errorcode = AuthErrorCode(rawValue: error!._code){
                                    switch errorcode{
                                    case .invalidEmail:
                                         self.showAlert("invalid  mail")
                                    default:
                                        self.showAlert("network issues")
                                    }
                                }
                            }else{
                                if let user = user{
                                    if self.segmentControl.selectedSegmentIndex == 0{
                                        let userData = ["provider":user.user.providerID,"email":email] as? [String:Any]
                                        DataService.instance.createFirebaseUser(uid: user.user.uid, userData: userData!, isDriver: false)
                                    }else{
                                        let userData = ["provider":user.user.providerID,"email":email,"userIsDriver":true,"isPickupModeEnabled":false,"driverIsOnTrip":false] as? [String:Any]
                                        DataService.instance.createFirebaseUser(uid: user.user.uid, userData: userData!, isDriver: true)
                                    }
                                }
                                print("successfulf regist")
                                self.dismiss(animated: true, completion: nil)
                                //
                            }
                        })
                    }
                }
            }
        }
    }
}
