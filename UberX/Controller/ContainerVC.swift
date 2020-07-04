//
//  ContainerVC.swift
//  UberX
//
//  Created by pop on 6/24/20.
//  Copyright © 2020 pop. All rights reserved.
//

import UIKit
import QuartzCore

enum SlideOutState{
    case collpased
    case leftPanelExpanded
}

enum ShowWhichVC{
    case homeVC
    case PaymentVC
}

var ShowVC:ShowWhichVC = .homeVC

class ContainerVC: UIViewController {
    var CurrnetState:SlideOutState = .collpased{
        didSet{
            let test = (CurrnetState != .collpased)
            shouldshowShadowForCenter(status: test)
        }
    }
    var homevc:HomeVC!
    var centerController:UIViewController!
    var LeftVC:LiftSidePanelVc!
    var isHidden = false
    var centralPanelExpandedOffset:CGFloat = 120
    var tap : UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initVC(Screen: .homeVC)
    }
    
    func initVC(Screen:ShowWhichVC){
        var presintingControler:UIViewController?
        ShowVC = Screen
        if homevc == nil{
            homevc = UIStoryboard.homeVC()
            homevc.delegate = self
        }
        presintingControler = homevc
        if let con = centerController{
            con.view.removeFromSuperview()
            con.removeFromParent()
        }
        centerController = presintingControler
        view.addSubview(centerController.view)
        addChild(centerController)
        centerController.didMove(toParent: self)
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        return UIStatusBarAnimation.slide
    }
    
    override var prefersStatusBarHidden: Bool{
        return isHidden
    }
}

extension ContainerVC:CenterVCDelegate{
    func ToggleLeftPanel() {
        let NotAlreadyExpanded = (CurrnetState != .leftPanelExpanded)
        if NotAlreadyExpanded{
            addLeftPanelViewController()
        }
        animateLeftPanel(shouldAnimate: NotAlreadyExpanded)
    }
    
    func addLeftPanelViewController() {
        if LeftVC == nil{
            LeftVC = UIStoryboard.LeftViewController()
            addChildPanelViewController(LeftVC)
        }
    }
    
    func addChildPanelViewController(_ slidePanelController:LiftSidePanelVc){
        view.insertSubview(slidePanelController.view, at: 0)
        addChild(slidePanelController)
        slidePanelController.didMove(toParent: self)
    }
    
    @objc func animateLeftPanel(shouldAnimate: Bool) {
        if shouldAnimate{
            isHidden = !isHidden
            animateStatusBar()
            setupWithCoverView()
            animatePanelCenterPoitionX(targetPosition: centerController.view.frame.width - centralPanelExpandedOffset)
        }else{
             isHidden = !isHidden
            animateStatusBar()
            hideCoverView()
            animatePanelCenterPoitionX(targetPosition: 0) { (finished) in
                if finished == true{
                    self.CurrnetState = .collpased
                    self.LeftVC = nil
                }
            }
        }
    }
    
    func animatePanelCenterPoitionX(targetPosition:CGFloat,Completion: ((Bool)->Void)! = nil){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.centerController.view.frame.origin.x = targetPosition
        }, completion: Completion)
    }
    
    func setupWithCoverView(){
        let whightCoverView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        whightCoverView.alpha = 0.0
        whightCoverView.backgroundColor = UIColor.white
        whightCoverView.tag = 25
        self.centerController.view.addSubview(whightCoverView)
        UIView.animate(withDuration: 0.2) {
            whightCoverView.alpha = 0.7
        }
        tap = UITapGestureRecognizer(target: self, action: #selector(animateLeftPanel(shouldAnimate:)))
        tap.numberOfTapsRequired = 1
        self.centerController.view.addGestureRecognizer(tap)
    }
    
    func hideCoverView(){
        self.centerController.view.removeGestureRecognizer(tap)
        for subview in self.centerController.view.subviews{
            if subview.tag == 25{
                UIView.animate(withDuration: 0.1, animations: {
                    subview.alpha = 0.0
                }) { (finished) in
                    subview.removeFromSuperview()
                }
            }
        }
    }
    
    func shouldshowShadowForCenter(status:Bool){
        if status == true{
            centerController.view.layer.shadowOpacity = 0.6
        }else{
            centerController.view.layer.shadowOpacity = 0.0
        }
    }
    
    func  animateStatusBar(){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
}

private extension UIStoryboard{
    class func MainStoryBoard()->UIStoryboard{
        return UIStoryboard(name: "Main", bundle: Bundle.main)
    }
    
    class func LeftViewController()->LiftSidePanelVc?{
        return MainStoryBoard().instantiateViewController(withIdentifier: "LiftSidePanelVc") as? LiftSidePanelVc
    }
    
    class func homeVC()->HomeVC?{
        return MainStoryBoard().instantiateViewController(withIdentifier: "HomeVC") as? HomeVC
    }
}
