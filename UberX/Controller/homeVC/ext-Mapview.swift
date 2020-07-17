//
//  ext-Mapview.swift
//  UberX
//
//  Created by pop on 7/11/20.
//  Copyright © 2020 pop. All rights reserved.
//

import UIKit
import MapKit

//MARK:- mapkit extension
extension HomeVC:MKMapViewDelegate{
    //MARK:- use UpdateServic class
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        UpdateService.instance.updateUserLocation(withlcation: userLocation.coordinate)
        UpdateService.instance.updateDriverLocation(withlcation: userLocation.coordinate)
        
        DataService.instance.userIsDriver(userKey: currentUser) { (status) in
            if status == true{
                DataService.instance.driverIsOnTrip(driverKey: self.currentUser!) { (isOnTrip, driverKey, TripKey) in
                    if isOnTrip == true{
                        self.zoom(toFitAnnotationFromMapView: self.MapView,forActiveTripWithDriver:true, withKey:driverKey)
                    }else{
                        self.centerUserLocation()
                    }
                }
            }else{
                DataService.instance.passengerIsOnTrip(passengerKey: self.currentUser!) { (isOnTrip, driverKey, tripKey) in
                    if isOnTrip == true{
                        self.zoom(toFitAnnotationFromMapView: self.MapView,forActiveTripWithDriver:true, withKey:driverKey)
                    }else{
                        self.centerUserLocation()
                    }
                }
            }
        }
    }
    //MARK:- add annotation in mapView
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

        shouldPresentLoadingView(false)
        
        return lineRendder
    }
    
    // MARK:- search func for destination result and put them in array in table view
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
    func searchMapKitforResultPolyline(forOriginMapItem OriginMapItem:MKMapItem?,withDestinationMapItem destinationMapItem:MKMapItem?){
        
        //Make request
        let request = MKDirections.Request()
        // make start point for rout
        if OriginMapItem == nil{
            request.source = MKMapItem.forCurrentLocation()
        }else{
            request.source = OriginMapItem
        }
        request.destination = destinationMapItem
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
            
            if self.MapView.overlays.count == 0{
               self.MapView.addOverlay(self.route!.polyline)
            }
            
            self.zoom(toFitAnnotationFromMapView: self.MapView,forActiveTripWithDriver:false, withKey:nil)
            
            let delegate = AppDelegate.getAppDelegate()
            delegate.window?.rootViewController?.shouldPresentLoadingView(false)
        }
        
    }
    //MARK:- zoom func
    func zoom(toFitAnnotationFromMapView mapView:MKMapView,forActiveTripWithDriver:Bool,withKey key:String?){
        //,forActiveTripWithDriver:Bool,withKey key:String?
        if mapView.annotations.count == 0{
            return
        }
        var topLeftCoordinate = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoordinate = CLLocationCoordinate2D(latitude: 90, longitude: -180)


        if forActiveTripWithDriver{
            for annotation in mapView.annotations {
                if let annotaion = annotation as? DriverAnnotation{
                    if annotaion.key == key{
                        topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                        topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                        bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                        bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                    }
                }else{
                    topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                    topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                    bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                    bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                }
            }
        }


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
    
    //MARK:- remove overlays and annotation
    func removeOverlaysAndAnnotations(forDriver:Bool?,forPasenger:Bool?){
        for annotation in MapView.annotations{
            if let annotation = annotation as? MKPointAnnotation{
                MapView.removeAnnotation(annotation)
            }
            if forDriver!{
                if let annotation = annotation as? DriverAnnotation{
                    MapView.removeAnnotation(annotation)
                }
            }
            if forPasenger!{
                if let annotation = annotation as? PassengerAnnotation{
                    MapView.removeAnnotation(annotation)
                }
            }
        }
        
        for overlay in MapView.overlays{
            if (overlay is MKPolyline){
                MapView.removeOverlay(overlay)
                
            }
        }
    }
    
    //MARK:- setCustomRegion
    func setCustomRegion(forAnnotationType type:AnnotationType,withcoordinate coordinate:CLLocationCoordinate2D){
        if type == .pickup{
            let pickupRegion = CLCircularRegion(center: coordinate, radius: 100, identifier: "pickup")
            manager?.startMonitoring(for: pickupRegion)
        }else if type == .destination{
            let destinationRegion = CLCircularRegion(center: coordinate, radius: 100, identifier: "destination")
            manager?.startMonitoring(for: destinationRegion)
        }
    }
}
