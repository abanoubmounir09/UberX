//
//  CenterVCDelegate.swift
//  UberX
//
//  Created by pop on 6/24/20.
//  Copyright © 2020 pop. All rights reserved.
//

import UIKit

protocol CenterVCDelegate {
    func ToggleLeftPanel()
    func addLeftPanelViewController()
    func animateLeftPanel(shouldAnimate:Bool)
}
