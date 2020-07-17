//
//  DataService.swift
//  UberX
//
//  Created by pop on 6/25/20.
//  Copyright © 2020 pop. All rights reserved.
//

import UIKit
import Firebase

let DB_Base = Database.database().reference()

class DataService{
    static let instance = DataService()
    private var _Ref_Base = DB_Base
    private var _Ref_Users = DB_Base.child("users")
    private var _Ref_Drivers = DB_Base.child("drivers")
    private var _Ref_Trips = DB_Base.child("trips")
    
    var Ref_Base : DatabaseReference{
        return _Ref_Base
    }
    var Ref_Users : DatabaseReference{
        return _Ref_Users
    }
    var Ref_Drivers : DatabaseReference{
        return _Ref_Drivers
    }
    var Ref_Trips : DatabaseReference{
        return _Ref_Trips
    }
    
     func createFirebaseUser(uid:String,userData:[String:Any],isDriver:Bool){
        if isDriver == true{
            Ref_Drivers.child(uid).updateChildValues(userData)
        }else{
            Ref_Users.child(uid).updateChildValues(userData)
        }
    }
    
    func driverIsAvailable(key:String?,handler:@escaping (_ status:Bool?)->Void){
        DataService.instance.Ref_Drivers.observeSingleEvent(of: .value) { (snapshot) in
            if let driversnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for driver in driversnapshot{
                    if driver.key == key{ //driverIsOnTrip
                        if driver.childSnapshot(forPath: "isPickupModeEnabled").value as? Bool == true{
                            if driver.childSnapshot(forPath: "driverIsOnTrip").value as? Bool == true{
                                handler(false)
                            }else{
                                handler(true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func driverIsOnTrip(driverKey:String?,handler:@escaping (_ status:Bool?,_ driverKey:String?,_ tripKey:String?)->Void){
        if driverKey != nil{
            DataService.instance.Ref_Drivers.child(driverKey!).child("driverIsOnTrip").observe(.value) { (driverTripStatusSnapShot) in
                   if let driverTripStatus = driverTripStatusSnapShot.value as? Bool{
                       if driverTripStatus == true {
                           DataService.instance.Ref_Trips.observeSingleEvent(of: .value) { (tripeSnapShot) in
                               if let tripsSnapShot = tripeSnapShot.children.allObjects as? [DataSnapshot]{
                                   for trip in tripsSnapShot {
                                       if trip.childSnapshot(forPath: "driverKey").value as? String == driverKey{
                                           handler(true,driverKey,trip.key)
                                       }else{
                                           return
                                       }
                                   }
                               }
                           }
                       }else{
                           handler(false,nil,nil)
                       }
                   }
               }
        }
   
    }
    
    
    func passengerIsOnTrip(passengerKey:String?,handler:@escaping(_ status:Bool?,_ driverKey:String?,_ tripKey:String?)->Void){
        DataService.instance.Ref_Trips.observe(.value) { (trisSnapShot) in
            if let tripSnap = trisSnapShot.children.allObjects as? [DataSnapshot]{
                for trip in tripSnap{
                    if trip.key == passengerKey{
                        if trip.childSnapshot(forPath: "tripIsAccepted").value as? Bool == true{
                            let driverkey = trip.childSnapshot(forPath: "driverKey").value as? String
                            handler(true,driverkey,trip.key)
                        }else{
                            handler(false,nil,nil)
                        }
                    }
                }
            }
        }
    }
    
    func userIsDriver(userKey:String?,handler:@escaping(_ status:Bool?)->Void){
        if userKey != nil{
            DataService.instance._Ref_Drivers.observeSingleEvent(of: .value) { (driverSnapShot) in
                       if let driverSnapShot = driverSnapShot.children.allObjects as? [DataSnapshot]{
                           for driver in driverSnapShot{
                               if  driver.key == userKey{
                                   handler(true)
                               }else{
                                   handler(false)
                               }
                           }
                       }
            }
        }
       
    }
    
    
    
    
    
    
    
    
    
}
