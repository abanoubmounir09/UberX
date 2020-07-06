//
//  RoundMapView.swift
//  UberX
//
//  Created by pop on 7/6/20.
//  Copyright © 2020 pop. All rights reserved.
//

import UIKit
import MapKit

class RoundMapView: MKMapView {
    override func awakeFromNib() {
        setupView()
    }

    func setupView(){
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 10.0
    }
}
