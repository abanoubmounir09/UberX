//
//  ViewController.swift
//  UberX
//
//  Created by pop on 6/23/20.
//  Copyright © 2020 pop. All rights reserved.
//

import UIKit
import MapKit
import RevealingSplashView
import Firebase
import CoreLocation

class HomeVC: UIViewController {
    
    @IBOutlet weak var CenterMapBtn: UIButton!
    @IBOutlet weak var REquestBTN: RoundedButton!
    @IBOutlet weak var MapView: MKMapView!
    @IBOutlet weak var destinationTextField: UITextField!
    
    //Variables
    @IBOutlet weak var destinationCircle: rondedView!
    var tableView = UITableView()
    var matchingItems:[MKMapItem] = [MKMapItem]()
    var regionRadios:CLLocationDistance = 1000
    var manager:CLLocationManager?
    var currentUser:String?
    
    var delegate:CenterVCDelegate?
    
    let revealingSplashView = RevealingSplashView(iconImage: #imageLiteral(resourceName: "driverAnnotation"), iconInitialSize: CGSize(width: 80, height: 80), backgroundColor: UIColor.white)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    
          manager = CLLocationManager()
              manager?.delegate = self
              manager?.desiredAccuracy = kCLLocationAccuracyBest
              
              checklocatinAuthorization()
        DataService.instance.Ref_Drivers.observe(.value) { (snap) in
            self.loadDriversAnnotationFromFB()
        }
             
               MapView.delegate = self
              destinationTextField.delegate = self
              centerUserLocation()
        currentUser  = Auth.auth().currentUser?.uid as! String
       // print("-------------------\(currentUser)")
        self.view.addSubview(revealingSplashView)
        revealingSplashView.animationType = .heartBeat
        revealingSplashView.startAnimation()
        revealingSplashView.heartAttack = true
    }
    
    func checklocatinAuthorization(){
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse{
            manager?.startUpdatingLocation()
        }else{
            manager?.requestWhenInUseAuthorization()
        }
    }
    
    func loadDriversAnnotationFromFB(){
        DataService.instance.Ref_Drivers.observe(.value) { (snapshot) in
            if let driverSnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for driver in driverSnapshot{
                    if driver.hasChild("coordinate"){
                        if driver.childSnapshot(forPath: "isPickupModeEnabled").value as? Bool == true{
                            if let driverDict = driver.value as? Dictionary<String,AnyObject>{
                                let coordinateArray = driverDict["coordinate"] as! NSArray
                                let driverCoordinate = CLLocationCoordinate2D(latitude: coordinateArray[0] as! CLLocationDegrees, longitude: coordinateArray[1] as! CLLocationDegrees)
                                let annotaion = DriverAnnotation(coordinate: driverCoordinate, withKey: driver.key)
                                
                                var driverIsVisible:Bool{
                                    return self.MapView.annotations.contains { (annotation) -> Bool in
                                        if let driverAnnotation = annotation as? DriverAnnotation{
                                            if driverAnnotation.key == driver.key{
                                                driverAnnotation.update(annotaionPostion: driverAnnotation, withcoordinate: driverCoordinate)
                                                return true
                                            }
                                        }
                                        return false
                                    }
                                }
                              
                                if !driverIsVisible{
                                      self.MapView.addAnnotation(annotaion)
                                }
                            }
                        }else{
                            for annotation in self.MapView.annotations{
                                if let annotation = annotation as? DriverAnnotation{
                                    if annotation.key == driver.key{
                                        self.MapView.removeAnnotation(annotation)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func centerUserLocation(){
        let cordinateRegion = MKCoordinateRegion(center: MapView.userLocation.coordinate, latitudinalMeters: regionRadios * 2, longitudinalMeters: regionRadios * 2)
        MapView.setRegion(cordinateRegion, animated: true)
    }

    @IBAction func RequestBTNwasPressed(_ sender: Any) {
        REquestBTN.animateButton(shouldLoad: true, withmessage: "")
    }
    
    @IBAction func centerMapBTNPressed(_ sender: Any) {
        centerUserLocation()
        CenterMapBtn.fadeTo(alphavalue: 0, duration: 0.3)
    }
    
    
    @IBAction func MenuBTNWasPressed(_ sender: Any) {
        delegate?.ToggleLeftPanel()
    }
}

extension HomeVC:CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse{
            MapView.showsUserLocation = true
            MapView.userTrackingMode = .follow
        }
    }
    
}
//MARK:- use UpdateServic class
extension HomeVC:MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        UpdateService.instance.updateUserLocation(withlcation: userLocation.coordinate)
        UpdateService.instance.updateDriverLocation(withlcation: userLocation.coordinate)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation{
            let identefier = "driver"
            var view : MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identefier)
            view.image = UIImage(named: "driverAnnotation")
            return view
        }else if let annotation = annotation as? PassengerAnnotation{
            let identifier = "passener"
            var view:MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: "currentLocationAnnotation")
            return view
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        CenterMapBtn.fadeTo(alphavalue: 1.0, duration: 0.3)
    }
    // MARK:- search func
    func performSearch(){
        matchingItems.removeAll()
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = destinationTextField.text
        request.region = MapView.region
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            if error != nil{
                print(error.debugDescription)
            }else if response?.mapItems.count == 0{
                print("no results")
            }else{
                for mapItem in response!.mapItems{
                    self.matchingItems.append(mapItem as MKMapItem)
                    self.tableView.reloadData()
                }
            }
        }
    }
}


