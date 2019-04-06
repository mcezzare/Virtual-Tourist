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
    
    // MARK: - Variables
    
    var pinAnnotation: MKPointAnnotation? = nil
    
    // MARK: - UIViewController Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        navigationItem.rightBarButtonItem = editButtonItem
        footerView.isHidden = true
        
        if let pins = loadAllPins() {
            showPins(pins)
        }
        
    }
    
    /// Used to remove pins on map
    ///
    /// - Parameters:
    ///   - editing: if is editing mode
    ///   - animated: animated mode
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        footerView.isHidden = !editing
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is PhotoAlbumViewController {
            guard let pin = sender as? Pin else {
                return
            }
            let controller = segue.destination as! PhotoAlbumViewController
            controller.pin = pin
        }
    }
    
    // MARK: - Actions
    
    
    /// Drop the pin on Map
    ///
    /// - Parameter sender: a long hold tap on screen
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
            
            _ = Pin(
                latitude: String(pinAnnotation!.coordinate.latitude),
                longitude: String(pinAnnotation!.coordinate.longitude),
                context: CoreDataManager.shared().context
            )
            save()
            print("\(#function) sender state: \(sender.state)")
        }
    }
    
    // MARK: - Helpers
    
    /// Fetch all Pins from database
    ///
    /// - Returns: list of Pins
    private func loadAllPins() -> [Pin]? {
        var pins: [Pin]?
        do {
            try pins = CoreDataManager.shared().fetchAllPins(entityName: Pin.name)
        } catch {
            print("\(#function) error:\(error)")
            showInfoAlert(withTitle: "Error", withMessage: "Error while fetching Pin locations: \(error)")
        }
        return pins
    }
    
    
    /// Fetch data from specific Pin from database
    ///
    /// - Parameters:
    ///   - latitude: latitude coordinate
    ///   - longitude: longitude coordinate
    /// - Returns: a Pin Entity
    private func loadPin(latitude: String, longitude: String) -> Pin? {
        let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", latitude, longitude)
        var pin: Pin?
        do {
            try pin = CoreDataManager.shared().fetchPin(predicate, entityName: Pin.name)
        } catch {
            print("\(#function) error:\(error)")
            showInfoAlert(withTitle: "Error", withMessage: "Error while fetching location: \(error)")
        }
        return pin
    }
    
    
    /// Load Pins on Map View
    ///
    /// - Parameter pins: pins loaded from DB
    func showPins(_ pins: [Pin]) {
        for pin in pins where pin.latitude != nil && pin.longitude != nil {
            let annotation = MKPointAnnotation()
            let lat = Double(pin.latitude!)!
            let lon = Double(pin.longitude!)!
            annotation.coordinate = CLLocationCoordinate2DMake(lat, lon)
            mapView.addAnnotation(annotation)
        }
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
}


// MARK: - Extensions

extension TravelLocationsViewController {
    
    // MARK: - MKMapViewDelegates
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
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
        let latitude = String(annotation.coordinate.latitude)
        let longitude = String(annotation.coordinate.longitude)
        if let pin = loadPin(latitude: latitude, longitude: longitude) {
            if isEditing {
                mapView.removeAnnotation(annotation)
                CoreDataManager.shared().context.delete(pin)
                save()
                return
            }
            // segue working..
            performSegue(withIdentifier: "showAlbum", sender: pin )
        }
    }
}
