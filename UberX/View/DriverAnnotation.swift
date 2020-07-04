//
//  DriverAnnotation.swift
//  UberX
//
//  Created by pop on 7/1/20.
//  Copyright © 2020 pop. All rights reserved.
//

import UIKit
import MapKit

class DriverAnnotation:NSObject,MKAnnotation{
    dynamic var coordinate:CLLocationCoordinate2D
    var key:String
    init(coordinate:CLLocationCoordinate2D,withKey key:String){
        self.coordinate = coordinate
        self.key = key
        super.init()
    }
    
    func update(annotaionPostion annotation:DriverAnnotation,withcoordinate coordinate2:CLLocationCoordinate2D){
        var location = self.coordinate
        location.latitude = coordinate2.latitude
        location.longitude = coordinate2.longitude
        UIView.animate(withDuration: 0.2) {
            self.coordinate = location
        }
        
    }
}
