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

enum AnnotationType{
    case pickup
    case destination
    case driver
}


class HomeVC: UIViewController,Alertable {
    
    @IBOutlet weak var CenterMapBtn: UIButton!
    @IBOutlet weak var REquestBTN: RoundedButton!
    @IBOutlet weak var MapView: MKMapView!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var cancelBTN: UIButton!
    
    //Variables
    @IBOutlet weak var destinationCircle: rondedView!
    
    var tableView = UITableView()
    var matchingItems:[MKMapItem] = [MKMapItem]()
    var regionRadios:CLLocationDistance = 1000
    var manager:CLLocationManager?
    var currentUser :String?// = Auth.auth().currentUser?.uid
    var selectedItemPlaceMark:MKPlacemark? = nil
    var delegate:CenterVCDelegate?
    var route:MKRoute!
    let revealingSplashView = RevealingSplashView(iconImage: #imageLiteral(resourceName: "driverAnnotation"), iconInitialSize: CGSize(width: 80, height: 80), backgroundColor: UIColor.white)
    
    override func viewDidLoad() {
        super.viewDidLoad()
              manager = CLLocationManager()
              manager?.delegate = self
              manager?.desiredAccuracy = kCLLocationAccuracyBest
              
              checklocatinAuthorization()
        
            DataService.instance.Ref_Drivers.observe(.value) { (snap) in
               self.loadDriversAnnotationFromFB()
                
                DataService.instance.passengerIsOnTrip(passengerKey: self.currentUser) { (isOnTrip, driverKey, tripKey) in
                    if isOnTrip == true{
                        self.zoom(toFitAnnotationFromMapView: self.MapView,forActiveTripWithDriver:true, withKey:driverKey)
                    }
                }
                
        }
             
               MapView.delegate = self
              destinationTextField.delegate = self
        
              centerUserLocation()
        currentUser  = Auth.auth().currentUser?.uid as? String
        self.view.addSubview(revealingSplashView)
        revealingSplashView.animationType = .heartBeat
        revealingSplashView.startAnimation()
        revealingSplashView.heartAttack = true
        
        //MARK:- notify drivers for trips retrn completion about available trips
        UpdateService.instance.observeTrips { (tripDict) in
            if tripDict != nil{
                let pickupCoordinateArray = tripDict["pickupCoordinate"] as?  NSArray
                    let tripKey = tripDict["passengerKey"] as? String
                    let acceptedStatus = tripDict["tripIsAccepted"] as? Bool
                if acceptedStatus == false{
                    DataService.instance.driverIsAvailable(key: self.currentUser!) { (available) in
                        if let avail = available{
                            if avail == true{
                                let storyBoard = UIStoryboard.init(name: "Main", bundle: Bundle.main)
                                let pickUpVC = storyBoard.instantiateViewController(withIdentifier: "PickUpVC") as? PickUpVC  
                                pickUpVC?.initData(coordinate: CLLocationCoordinate2D(latitude: pickupCoordinateArray![0] as! CLLocationDegrees, longitude: pickupCoordinateArray![1] as! CLLocationDegrees), pasengerKey: tripKey!)
                                self.present(pickUpVC!, animated: true, completion: nil)
                            }

                        }
                    }
                }
            }
        }
        
    }
    
    //MARK:- view will appear -> driver is Available
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        DataService.instance.Ref_Trips.observe(.childRemoved) { (removedTripSnapShot) in
            let removedTripdict = removedTripSnapShot.value as? [String:AnyObject]
            if removedTripdict?["driverKey"] != nil{
                DataService.instance.Ref_Drivers.child(removedTripdict?["driverKey"] as! String).updateChildValues(["driverIsOnTrip":false])
            }
                DataService.instance.userIsDriver(userKey: self.currentUser!) { (isDriver) in
                    if isDriver == true{
                        //remove all map notationand overlays
                        self.removeOverlaysAndAnnotations(forDriver: false, forPasenger: true)
                    }else{
                        self.cancelBTN.fadeTo(alphavalue: 0.0, duration: 0.2)
                        self.destinationTextField.isUserInteractionEnabled = true
                        //remove all map notationand overlays
                        self.removeOverlaysAndAnnotations(forDriver: false, forPasenger: true)
                        self.centerUserLocation()
                    }
                }
            
        }

        DataService.instance.driverIsOnTrip(driverKey: self.currentUser) { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true{
                DataService.instance.Ref_Trips.observeSingleEvent(of: .value) { (tripsSnapShot) in
                    if let tripsSnapShot = tripsSnapShot.children.allObjects as? [DataSnapshot]{
                        for trip in tripsSnapShot{
                            if trip.childSnapshot(forPath: "driverKey").value as? String == self.currentUser!{
                                let pickUpCoordinateArray = trip.childSnapshot(forPath: "pickupCoordinate").value as? NSArray
                                let pickupCoordinate = CLLocationCoordinate2D(latitude:pickUpCoordinateArray![0] as! CLLocationDegrees , longitude: pickUpCoordinateArray![1] as! CLLocationDegrees)
                                let pickupPlacMark = MKPlacemark(coordinate: pickupCoordinate)
                                self.dropPibForPlacMark(placeMark: pickupPlacMark)
                    
                                self.searchMapKitforResultPolyline(forOriginMapItem: nil,withDestinationMapItem: MKMapItem(placemark: pickupPlacMark))
                                self.setCustomRegion(forAnnotationType: .pickup, withcoordinate: pickupCoordinate)
                            }
                        }
                    }
                }
            }
            
        }
        
         connectUserAndDriverForTrip()
       
    }
    
    func checklocatinAuthorization(){
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse{
            manager?.startUpdatingLocation()
        }else{
            manager?.requestWhenInUseAuthorization()
        }
    }
    
    //MARK:- loadDriversAnnotationFromFB
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
    
     //MARK:- connectUserAndDriverForTrip and show rout between passenger and driver on map
    func connectUserAndDriverForTrip(){
        DataService.instance.passengerIsOnTrip(passengerKey: self.currentUser) { (isOnTrip, deiverKey, tripKey) in
            if isOnTrip == true{
                self.removeOverlaysAndAnnotations(forDriver: false, forPasenger: true)
                
                DataService.instance.Ref_Trips.child(tripKey!).observeSingleEvent(of: .value) { (tripSnapShot) in
                    let tripDict = tripSnapShot.value as? Dictionary<String,AnyObject>
                    if tripDict?["tripIsAccepted"] as? Bool == true{
//                        self.removeOverlaysAndAnnotations(forDriver: false, forPasenger: true)
                        
                        let driverID = tripDict?["driverKey"] as! String
                
                        let pickUpCoordinateArray = tripDict?["pickupCoordinate"] as! NSArray
                        let pickUpCoordinate = CLLocationCoordinate2D(latitude: pickUpCoordinateArray[0] as! CLLocationDegrees, longitude: pickUpCoordinateArray[1] as! CLLocationDegrees)
                        let pickupPlaceMark = MKPlacemark(coordinate: pickUpCoordinate)
                        let pickupMapItem = MKMapItem(placemark: pickupPlaceMark)
                        
                        DataService.instance.Ref_Drivers.child(driverID).child("coordinate").observeSingleEvent(of: .value) { (coordinateSnapshot) in
                            let coordinateSnapShot = coordinateSnapshot.value as! NSArray
                            
                            let driverCoordinate = CLLocationCoordinate2D(latitude: coordinateSnapShot[0] as! CLLocationDegrees, longitude: coordinateSnapShot[1] as! CLLocationDegrees)
                                        let driverPlaceMark = MKPlacemark(coordinate: driverCoordinate)
                                        let driverMapItem = MKMapItem(placemark: driverPlaceMark)
                                        
                                        let passengerAnnotation = PassengerAnnotation(Initcoordinate: pickUpCoordinate, Initkey: self.currentUser!)
//
                                        self.MapView.addAnnotation(passengerAnnotation)
                                        
                                        self.searchMapKitforResultPolyline(forOriginMapItem: driverMapItem, withDestinationMapItem: pickupMapItem)
                                                   
                            
                            
                                        self.REquestBTN.isUserInteractionEnabled = false
                                                    
                
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
    
    //MAARK:- Action btn to requset trip
    @IBAction func RequestBTNwasPressed(_ sender: Any) {
        UpdateService.instance.updateTripWithCoordinateUponREquest()
        
      //  REquestBTN.animateButton(shouldLoad: true, withmessage: "")
        self.view.endEditing(true)
        self.destinationTextField.isUserInteractionEnabled = false
    }
    
    //MARK:- cancel Trip
    @IBAction func cancelBTNTrip(_ sender: Any) {
        DataService.instance.driverIsOnTrip(driverKey: currentUser!) { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true {
                        UpdateService.instance.CancelTrip(withPassengerKey: tripKey!, withDriverKey: driverKey!)
                    }
              }
        
        DataService.instance.passengerIsOnTrip(passengerKey: currentUser!) { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true {
                UpdateService.instance.CancelTrip(withPassengerKey: self.currentUser!, withDriverKey: driverKey!)
            }else{
                 UpdateService.instance.CancelTrip(withPassengerKey: self.currentUser!, withDriverKey: nil)
            }
        }
        
      self.REquestBTN.isUserInteractionEnabled = true
        
    }
    @IBAction func centerMapBTNPressed(_ sender: Any) {
        DataService.instance.Ref_Users.observe(.value) { (snapshot) in
                   if let Usersnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                       for user in Usersnapshot{
                           if user.key == self.currentUser{
                               if user.hasChild("tripCoordinate"){
                                self.zoom(toFitAnnotationFromMapView: self.MapView,forActiveTripWithDriver:false, withKey:nil)
                                   self.CenterMapBtn.fadeTo(alphavalue: 0.0, duration: 0.2)
                               }else{
                                self.centerUserLocation()
                                self.CenterMapBtn.fadeTo(alphavalue: 0, duration: 0.3)
                               }
                           }
                       }
                   }
               }
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
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        DataService.instance.driverIsOnTrip(driverKey: currentUser,handler:  { (isOnTrip, driverKey, passengerKey) in
            if isOnTrip == true{
                if region.identifier == "pickup"{
                    print("driver entered region")
                    self.REquestBTN.setTitle("START TRIP", for: .normal)
                }else if region.identifier == "destination"{
                    self.cancelBTN.fadeTo(alphavalue: 0.0, duration: 0.2)
                    self.cancelBTN.isHidden = true
                    self.REquestBTN.setTitle("END TRIP", for: .normal)
                }
            }
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        DataService.instance.driverIsOnTrip(driverKey: currentUser,handler:  { (isOnTrip, driverKey, passengerKey) in
            if isOnTrip == true{
                if region.identifier == "pickup"{
                     print("driver exite region")
                    //load direction to pickup
                    self.REquestBTN.setTitle("GET DIRECTION ", for: .normal)
                }else if region.identifier == "destination"{
                   //load direction to destination
                    self.REquestBTN.setTitle("GET DIRECTION", for: .normal)
                }
            }
        })
    }
    
}



