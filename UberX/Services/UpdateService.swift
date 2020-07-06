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

class UpdateService:HomeVC {
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
    
    func observeTrips(handler:@escaping (_ coordinateDict:Dictionary<String,AnyObject>)->Void){
        DataService.instance.Ref_Trips.observe(.value) { (snapshot) in
            if let tripsSnapShot = snapshot.children.allObjects as? [DataSnapshot]{
                for trip in tripsSnapShot{
                    if trip.hasChild("passengerKey") &&  trip.hasChild("tripIsAccepted"){
                        if let tripDict = trip.value as? Dictionary<String,AnyObject>{
                            handler(tripDict)
                        }
                    }
                }
            }
        }
    }
    
    func updateTripWithCoordinateUponREquest(){
        DataService.instance.Ref_Users.child(currentUser!).observeSingleEvent(of: .value,with: { (snapshot) in
            let userSnapShot = snapshot.children.allObjects as? DataSnapshot
            if userSnapShot?.hasChild("userIsDriver") == false{
                if let userDict = userSnapShot?.value as? Dictionary<String,AnyObject>{
                    let pickUpArray = userDict["coordinate"] as! NSArray
                    let destinationArray = userDict["tripCoordinate"] as! NSArray
                    DataService.instance.Ref_Trips.child(userSnapShot!.key).updateChildValues(["pickupCoordinate":[pickUpArray[0],pickUpArray[1]],"destinationCoordinate":[destinationArray[0],destinationArray[1]],"passengerKey":userSnapShot!.key,"tripIsAccepted":false])
                }
            }else{
                
            }
        })
    }
}
