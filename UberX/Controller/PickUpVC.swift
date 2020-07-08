//
//  PickUpVC.swift
//  UberX
//
//  Created by pop on 7/6/20.
//  Copyright © 2020 pop. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class PickUpVC: UIViewController {

    @IBOutlet weak var pickUpMapView: RoundMapView!
    
    //MARK:- VAriables
    var regionDestance:CLLocationDistance = 2000
    var pin:MKPlacemark? = nil
    var pickupCoordinate:CLLocationCoordinate2D!
    var passengerKey:String!
    var locationPlaceMark:MKPlacemark!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickUpMapView.delegate = self
        locationPlaceMark = MKPlacemark(coordinate: pickupCoordinate)
        dropPinFor(placmark: locationPlaceMark)
        CenterMapLocation(location: locationPlaceMark.location!)
        
        DataService.instance.Ref_Trips.child(passengerKey).observe(.value) { (tripSnapshot) in
            if tripSnapshot.exists(){
                if tripSnapshot.childSnapshot(forPath: "tripIsAccepted").value as? Bool == true{
                     self.dismiss(animated: true, completion: nil)
                }
            }else{
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
//    
    func initData(coordinate:CLLocationCoordinate2D,pasengerKey:String){
        self.pickupCoordinate = coordinate
        self.passengerKey = pasengerKey
    }
   
    @IBAction func AcceptBTNWasPressed(_ sender: Any) {
        UpdateService.instance.acceptTrip(withPassengerKey: passengerKey, withDriverKey: Auth.auth().currentUser!.uid)
        presentingViewController?.shouldPresentLoadingView(true)
    }
    
    @IBAction func CancelBTNWaPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
//    
//
}
//
extension PickUpVC:MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "PickUpPoint"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil{
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }else{
            annotationView?.annotation = annotation
        }
        annotationView?.image = UIImage(named: "destinationAnnotation")
        return annotationView
    }
    
    func CenterMapLocation(location:CLLocation){
    
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionDestance  , longitudinalMeters: regionDestance )
        pickUpMapView.setRegion(coordinateRegion, animated: true)
    }
    
    func dropPinFor(placmark:MKPlacemark){
        pin = placmark
        for annotation in pickUpMapView.annotations{
            pickUpMapView.removeAnnotation(annotation)
        }
        let annotaion = MKPointAnnotation()
        annotaion.coordinate = placmark.coordinate
        pickUpMapView.addAnnotation(annotaion)
    }
    }

