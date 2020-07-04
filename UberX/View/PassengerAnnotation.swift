//
//  PassengerAnnotation.swift
//  UberX
//
//  Created by pop on 7/4/20.
//  Copyright © 2020 pop. All rights reserved.
//

import Foundation
import MapKit

class PassengerAnnotation:NSObject,MKAnnotation{
    dynamic var coordinate:CLLocationCoordinate2D
    var key:String
    init(Initcoordinate:CLLocationCoordinate2D,Initkey:String){
        self.coordinate = Initcoordinate
        self.key = Initkey
        super.init()
    }
    
    
}
