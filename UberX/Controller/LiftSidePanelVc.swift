//
//  LiftSidePanelVc.swift
//  UberX
//
//  Created by pop on 6/24/20.
//  Copyright © 2020 pop. All rights reserved.
//

import UIKit
import Firebase

class LiftSidePanelVc: UIViewController {
    
    let appdelegate = AppDelegate.getAppDelegate()
    
    let currentUserID = Auth.auth().currentUser?.uid
    @IBOutlet weak var userEmail: UILabel!
    @IBOutlet weak var pickupmodelb: UILabel!
    @IBOutlet weak var userAccontType: UILabel!
    @IBOutlet weak var userImge: RoundImage!
    @IBOutlet weak var pickerSwitch: UISwitch!
    @IBOutlet weak var LoginOutBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pickerSwitch.isHidden = true
        pickupmodelb.isHidden = true
        observePassengerAndDrivers()
        if Auth.auth().currentUser == nil{
            userEmail.text = ""
            userAccontType.text = ""
            //pickupmodelb.text = ""
            userImge.isHidden = true
             LoginOutBtn.setTitle("Sign Un / Login", for: .normal)
        }else{
            userEmail.text = Auth.auth().currentUser?.email
            userImge.isHidden = false
            LoginOutBtn.setTitle("LogOut", for: .normal)
        }
    }
    
    func observePassengerAndDrivers(){
        DataService.instance.Ref_Users.observeSingleEvent(of: .value) { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for snap in snapshot{
                    if snap.key == Auth.auth().currentUser?.uid{
                        self.userAccontType.text  = "passenger"
                    }
                }
            }
        }//end query
        
        DataService.instance.Ref_Drivers.observeSingleEvent(of: .value) { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for snap in snapshot{
                    if snap.key == Auth.auth().currentUser?.uid{
                        self.userAccontType.text  = "Driver"
                        self.pickupmodelb.isHidden = false
                        self.pickerSwitch.isHidden = false
                        let switchStatus = snap.childSnapshot(forPath: "isPickupModeEnabled").value as? Bool
                        self.pickerSwitch.isOn = switchStatus!
                    }
                }
            }
        }//end query
        
    }//end func
    
    @IBAction func SwitchWasToggled(_ sender: Any) {
        if pickerSwitch.isOn {
            pickupmodelb.text = "Picker Mode Enabled"
            DataService.instance.Ref_Drivers.child(currentUserID!).updateChildValues(["isPickupModeEnabled" : true])
            appdelegate.MenuContainerVC.ToggleLeftPanel()
        }else{
            pickupmodelb.text = "Picker Mode Disabled"
            DataService.instance.Ref_Drivers.child(currentUserID!).updateChildValues(["isPickupModeEnabled" : false])
            appdelegate.MenuContainerVC.ToggleLeftPanel()
        }
    }
    
 
    @IBAction func SingUPBTNPressed(_ sender: Any) {
        if Auth.auth().currentUser == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let loginvc = storyboard.instantiateViewController(withIdentifier: "loginVC") as? LoginVC
            present(loginvc!, animated: true, completion: nil)
        }else{
            do{
                try Auth.auth().signOut()
                userEmail.text = ""
                userAccontType.text = ""
                userImge.isHidden = true
                pickerSwitch.isHidden = true
                pickupmodelb.text = ""
                LoginOutBtn.setTitle("Sign Un / Login", for: .normal)
            }catch{
                print(error.localizedDescription)
            }
        }
     
    }
    
}
