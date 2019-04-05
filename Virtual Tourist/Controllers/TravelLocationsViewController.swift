//
//  TravelLocationsViewController.swift
//  Virtual Tourist
//
//  Created by Mario Cezzare on 04/04/19.
//  Copyright © 2019 Mario Cezzare. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class TravelLocationsViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var mapView:MKMapView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var deletePinsButton:UIButton!
    
    // MARK: - Variables
    var pinAnnotation: MKPointAnnotation? = nil
    
    // MARK: - UIViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        navigationItem.rightBarButtonItem = editButtonItem
        footerView.isHidden = true
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        footerView.isHidden = !editing
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PhotoAlbumViewController {
            //            guard let pin = sender as? Pin else {
            //                return
            //            }
            let controller = segue.destination as! PhotoAlbumViewController
            //            controller.pin = pin
        }
    }
    
    // MARK: - Actions
    
    @IBAction func addPinGesture(_ sender: UILongPressGestureRecognizer) {
        
        let location = sender.location(in: mapView)
        let locCoord = mapView.convert(location, toCoordinateFrom: mapView)
        
        if sender.state == .began {
            
            pinAnnotation = MKPointAnnotation()
            pinAnnotation!.coordinate = locCoord
            // TODO: add a reverseGeocodeLocation to toolTip
            //            pinAnnotation?.title = "Test"
            //            pinAnnotation?.subtitle = "SubTitle test"
            
            print("\(#function) Coordinate: \(locCoord.latitude),\(locCoord.longitude)")
            print("\(#function) Location: \(location),\(location.debugDescription)")
            
            mapView.addAnnotation(pinAnnotation!)
            
        } else if sender.state == .changed {
            pinAnnotation!.coordinate = locCoord
        } else if sender.state == .ended {
            
            //            _ = Pin(
            //                latitude: String(pinAnnotation!.coordinate.latitude),
            //                longitude: String(pinAnnotation!.coordinate.longitude),
            //                context: CoreDataStack.shared().context
            //            )
            //            save()
            print("\(#function) sender state: \(sender.state)")
        }
    }
}

// MARK: - Extensions

extension TravelLocationsViewController {
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView!.animatesDrop = true
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else {
            return
        }
        
        mapView.deselectAnnotation(annotation, animated: true)
        print("\(#function) lat \(annotation.coordinate.latitude) lon \(annotation.coordinate.longitude)")
//        let lat = String(annotation.coordinate.latitude)
//        let lon = String(annotation.coordinate.longitude)
        // segue working..
        performSegue(withIdentifier: "showAlbum", sender: annotation )
    }
}
