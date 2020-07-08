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

class HomeVC: UIViewController,Alertable {
    
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
        }
             
               MapView.delegate = self
              destinationTextField.delegate = self
              centerUserLocation()
        currentUser  = Auth.auth().currentUser?.uid as! String
        self.view.addSubview(revealingSplashView)
        revealingSplashView.animationType = .heartBeat
        revealingSplashView.startAnimation()
        revealingSplashView.heartAttack = true
        
        //MARK:- retrn completion about available trips
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
    
    //MAARK:- Action btn to requset trip
    @IBAction func RequestBTNwasPressed(_ sender: Any) {
        UpdateService.instance.updateTripWithCoordinateUponREquest()
      //  REquestBTN.animateButton(shouldLoad: true, withmessage: "")
        self.view.endEditing(true)
        self.destinationTextField.isUserInteractionEnabled = false
    }
    
    @IBAction func centerMapBTNPressed(_ sender: Any) {
        DataService.instance.Ref_Users.observe(.value) { (snapshot) in
                   if let Usersnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                       for user in Usersnapshot{
                           if user.key == self.currentUser{
                               if user.hasChild("tripCoordinate"){
                                   self.zoom(toFitAnnotationFromMapView: self.MapView)
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
    
}
//MARK:- mapkit extension
extension HomeVC:MKMapViewDelegate{
    //MARK:- use UpdateServic class
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
        }else if let annotation = annotation as? MKPointAnnotation{
            let identifier = "destination"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if annotationView == nil{
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }else{
                annotationView?.annotation = annotation
            }
            annotationView?.image = UIImage(named: "destinationAnnotation")
            return annotationView
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        CenterMapBtn.fadeTo(alphavalue: 1.0, duration: 0.3)
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let lineRendder = MKPolylineRenderer(overlay: self.route.polyline)
        lineRendder.strokeColor = UIColor(red: 216/255, green: 71/255, blue: 30/255, alpha: 0.75)
        lineRendder.lineWidth = 3
        return lineRendder
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
                 self.showAlert(error.debugDescription)
            }else if response?.mapItems.count == 0{
                self.showAlert("no results")
            }else{
                for mapItem in response!.mapItems{
                    self.matchingItems.append(mapItem as MKMapItem)
                    self.tableView.reloadData()
                    self.shouldPresentLoadingView(false)
                }
            }
        }
        
    }
    
    //MARK:- drop Pin For Destination
    func dropPibForPlacMark(placeMark:MKPlacemark){
        selectedItemPlaceMark = placeMark
        for annotaion in MapView.annotations{
            if annotaion.isKind(of: MKPointAnnotation.self){
                MapView.removeAnnotation(annotaion)
            }
        }
        let annotation = MKPointAnnotation()
        annotation.coordinate = selectedItemPlaceMark?.coordinate as! CLLocationCoordinate2D
        MapView.addAnnotation(annotation)
    }
    
    //MARK:- get the rout for destination
    func searchMapKitforResultPolyline(forMapItem mapItem:MKMapItem){
       
        //Make request
        let request = MKDirections.Request()
        // make start point for rout
        request.source = MKMapItem.forCurrentLocation()
        request.destination = mapItem
        //generate route for car
        request.transportType = MKDirectionsTransportType.automobile
        let direction = MKDirections(request: request)
        direction.calculate { (response, error) in
            guard let response = response else{
                self.showAlert(error!.localizedDescription)
                return
            }
            // first rout is the best
            
            self.route = response.routes[0]
            self.MapView.addOverlay(self.route.polyline)
            self.shouldPresentLoadingView(false)
        }
        
    }
    
    func zoom(toFitAnnotationFromMapView mapView:MKMapView){
        if mapView.annotations.count == 0{
            return
        }
        var topLeftCoordinate = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoordinate = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        for annotation in mapView.annotations where !annotation.isKind(of: DriverAnnotation.self){
            topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
            topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
            bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
            bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
        }
        
        var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: topLeftCoordinate.latitude - (topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 0.5, longitude: topLeftCoordinate.longitude + (bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 0.5), span: MKCoordinateSpan(latitudeDelta: fabs(topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 2.0, longitudeDelta: fabs(bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 2.0))
        region = mapView.regionThatFits(region)
        mapView.setRegion(region, animated: true)
    }
    
    
    
}


