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
    
}
