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
    
    
}
