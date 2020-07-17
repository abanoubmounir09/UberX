//
//  TEXTField-EXT.swift
//  UberX
//
//  Created by pop on 7/2/20.
//  Copyright © 2020 pop. All rights reserved.
//

import UIKit
import Firebase
import MapKit

extension HomeVC:UITextFieldDelegate{
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == destinationTextField{
            print("editing")
            tableView.frame = CGRect(x: 20.0, y: view.frame.height, width: view.frame.width - 40, height: view.frame.height - 150)
            tableView.layer.cornerRadius = 5.0
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "locationCell")
            tableView.delegate = self
            tableView.dataSource = self
            tableView.tag = 13
            tableView.rowHeight = 60
            view.addSubview(tableView)
            AnimateTableView(shouldShow: true)
            
            UIView.animate(withDuration: 0.2) {
                self.destinationCircle.backgroundColor = UIColor.red
                self.destinationCircle.borderColor  = UIColor.init(red: 199/255, green: 0/255, blue: 0/255, alpha: 1.0)
            }
        }

    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == destinationTextField{
            //MARK:- use of Serach Func()
            self.performSearch()
            shouldPresentLoadingView(true)
            view.endEditing(true)
        }
        shouldPresentLoadingView(false)
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == destinationTextField{
            if destinationTextField.text == ""{
                 UIView.animate(withDuration: 0.2) {
                    self.destinationCircle.backgroundColor = UIColor.gray
                    self.destinationCircle.borderColor = UIColor.gray
                }
            }
        } //
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        matchingItems.removeAll()
        tableView.reloadData()
        //remove  user location form firebase
        DataService.instance.Ref_Users.child(currentUser!).child("tripCoordinate").removeValue()
        MapView.removeOverlays(MapView.overlays)
        for annotaion in MapView.annotations{
            if annotaion.isKind(of: MKPointAnnotation.self){
                MapView.removeAnnotation(annotaion)
            }else if annotaion.isKind(of: PassengerAnnotation.self){
                MapView.removeAnnotation(annotaion)
            }
        }
         // remove table by two way
        tableView.removeFromSuperview()
        //
//        for subview in self.view.subviews{
//            if subview.tag == 13 {
//                subview.removeFromSuperview()
//            }
//        }
        centerUserLocation()
        return true
    }
    
    //MARK:- func to show and hide tableview
    func AnimateTableView(shouldShow:Bool){
        if shouldShow{
            UIView.animate(withDuration: 0.2) {
                self.tableView.frame = CGRect(x: 20.0, y: 170, width: self.view.frame.width - 40, height: self.view.frame.height - 170)
            }
        }else{
            UIView.animate(withDuration: 0.2, animations: {
                self.tableView.frame = CGRect(x: 20.0, y: self.view.frame.height, width: self.view.frame.width - 40, height: self.view.frame.height - 150)
            }) { (finished) in
                for subview in self.view.subviews{
                    if subview.tag == 13 {
                        subview.removeFromSuperview()
                    }
                }
            }
        }
    }
    
}

extension HomeVC:UITableViewDataSource,UITableViewDelegate{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "locationCell")
        let mapItem = matchingItems[indexPath.row]
        cell.textLabel?.text = mapItem.name
        cell.detailTextLabel?.text = mapItem.placemark.title
        return cell ?? UITableViewCell()
    }
    //MARK:- did select row
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        //To remove any polyline
//        if route != nil{
//             self.MapView.removeOverlay(self.route.polyline)
//        }
        shouldPresentLoadingView(true)
        //MARK:- get passenger location and put annotaion
        let passengerCoordinate = manager?.location?.coordinate
        let passengerAnnotation = PassengerAnnotation(Initcoordinate: passengerCoordinate!, Initkey: currentUser!)
         MapView.addAnnotation(passengerAnnotation)
        destinationTextField.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
        
        let selectedMapItem = matchingItems[indexPath.row]
        let ItemCoordinate = selectedMapItem.placemark.coordinate
        DataService.instance.Ref_Users.child(currentUser!).updateChildValues(["tripCoordinate":[ItemCoordinate.latitude, ItemCoordinate.longitude ]])
        dropPibForPlacMark(placeMark: selectedMapItem.placemark)
        
        searchMapKitforResultPolyline(forOriginMapItem :nil,withDestinationMapItem :selectedMapItem)
       
        AnimateTableView(shouldShow: false)
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
         if destinationTextField.text == ""{
                   AnimateTableView(shouldShow: false)
               }
    }
}


