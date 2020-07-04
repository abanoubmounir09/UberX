//
//  UpdateService.swift
//  UberX
//
//  Created by pop on 6/26/20.
//  Copyright © 2020 pop. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import MapKit

class UpdateService {
    static var instance = UpdateService()
    
    func updateUserLocation(withlcation coordinate:CLLocationCoordinate2D){
        DataService.instance.Ref_Users.observeSingleEvent(of: .value,with: { (snapshot) in
            if let usersnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for user in usersnapshot{
                    if user.key == Auth.auth().currentUser?.uid{
                        DataService.instance.Ref_Users.child(user.key).updateChildValues(["coordinate":[coordinate.latitude,coordinate.longitude]])
                    }
                }
            }
        })
    }
    
    func updateDriverLocation(withlcation coordinate:CLLocationCoordinate2D){
        DataService.instance.Ref_Drivers.observeSingleEvent(of: .value,with: { (snapshot) in
            if let driverSnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for driver in driverSnapshot{
                    if driver.key == Auth.auth().currentUser?.uid{
                        if driver.childSnapshot(forPath: "isPickupModeEnabled").value as? Bool == true{
                        DataService.instance.Ref_Drivers.child(driver.key).updateChildValues(["coordinate":[coordinate.latitude,coordinate.longitude]])
                        }
                    }
                }
            }
        })
    }
}
