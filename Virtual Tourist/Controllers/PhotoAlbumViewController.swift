//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Mario Cezzare on 04/04/19.
//  Copyright © 2019 Mario Cezzare. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout?
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var labelStatus: UILabel!
    @IBOutlet weak var trashButton: UIBarButtonItem!
    
    // MARK: - Variables
    
    var selectedIndexes = [IndexPath]()
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    var totalPages: Int? = nil
    
    var displayAlertForInvalidImages = false
    var pin: Pin?
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    // MARK: - UIViewController lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateFlowLayout(view.frame.size)
        mapView.delegate = self
        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        
        // Cleanup the Label
        updateStatusLabel("")
        
        guard let pin = pin else {
            return
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadStarted), name: .reloadStarted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadCompleted), name: .reloadCompleted, object: nil)
        
        showOnTheMap(pin)
        setupFetchedResultControllerWith(pin)
        
        if let photos = pin.photos, photos.count == 0 {
            // pin selected has no photos
            fetchPhotosFromAPI(pin)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateFlowLayout(size)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Actions
    
    /// Delete all photos from DB and get new from Flickr API
    ///
    /// - Parameter sender: new collection button
    @IBAction func deleteAction(_ sender: Any) {
        // delete all photos
        for photos in fetchedResultsController.fetchedObjects! {
            CoreDataManager.shared().context.delete(photos)
        }
        save()
        fetchPhotosFromAPI(pin!)
    }
    
    
    /// Ask for confirmation to delete photos selected in collection
    ///
    /// - Parameter sender: trash bar iten button
    @IBAction func deletePhotos(_ sender: Any) {
        
        if self.selectedIndexes.count == 0 {
            showInfoAlert(withTitle: "No images selected.", withMessage: "Tap at one or more images to remove.")
            return
        }
        
        let confirmMessage = "Remove selected itens?"
        self.showConfirmationAlert(withMessage: confirmMessage, actionTitle: "Remove") {
            // code to remove itens from collection and from DB.
            for item in self.selectedIndexes {
                print("Removing \(item)")
                let photoToDelete = self.fetchedResultsController.object(at: item)
                CoreDataManager.shared().context.delete(photoToDelete)
                
            }
            self.save()
        }
        
    }
    
    // MARK: - Helpers
    
    
    /// Initialize the Fetch Request from DB
    ///
    /// - Parameter pin: pin entity
    private func setupFetchedResultControllerWith(_ pin: Pin) {
        
        let fetchRequest = NSFetchRequest<Photo>(entityName: Photo.name)
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", argumentArray: [pin])
        
        // Create the fRC
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataManager.shared().context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        // Start the fRC
        var error: NSError?
        do {
            try fetchedResultsController.performFetch()
        } catch let catchedError as NSError {
            error = catchedError
        }
        
        if let error = error {
            print("\(#function) Error performing initial fetch: \(error)")
        }
    }
    
    
    /// Make the Requests to Flickr API from a specific PIN(location)
    ///
    /// - Parameter pin: pin entity
    private func fetchPhotosFromAPI(_ pin: Pin) {
        let lat = Double(pin.latitude!)!
        let lon = Double(pin.longitude!)!
        
        NotificationCenter.default.post(name: .reloadStarted, object:nil)
        activityIndicator.startAnimating()
        self.updateStatusLabel("Fetching photos ...")
        
        Client.shared().searchFlickrImages(latitude: lat, longitude: lon, totalPages: totalPages) { (photosParsed, error) in
            self.performUIUpdatesOnMain {
                self.activityIndicator.stopAnimating()
                self.labelStatus.text = ""
            }
            
            if let photosParsed = photosParsed {
                self.totalPages = photosParsed.photos.pages
                let totalPhotos = photosParsed.photos.photo.count
                print("\(#function) Downloading \(totalPhotos) photos.")
                self.storePhotos(photosParsed.photos.photo, forPin: pin)
                
                if totalPhotos == 0 {
                    self.updateStatusLabel("No photos found for this location.")
                    NotificationCenter.default.post(name: .reloadCompleted, object:nil)
                }
            } else if let error = error {
                print("\(#function) error:\(error)")
                self.showInfoAlert(withTitle: "Error", withMessage: error.localizedDescription)
                self.updateStatusLabel("Something went wrong, please try again.")
            }
            
        }
        //        NotificationCenter.default.post(name: .reloadCompleted, object:nil)
    }
    
    private func updateStatusLabel(_ text: String) {
        self.performUIUpdatesOnMain {
            self.labelStatus.text = text
        }
    }
    
    
    /// Save the photos in DB
    ///
    /// - Parameters:
    ///   - photos: photos from json data
    ///   - forPin: forPin entity
    private func storePhotos(_ photos: [PhotoFlickr], forPin: Pin) {
        func showErrorMessage(msg: String) {
            showInfoAlert(withTitle: "Error", withMessage: msg)
        }
        NotificationCenter.default.post(name: .reloadStarted, object:nil)
        for photo in photos {
            performUIUpdatesOnMain {
                if let url = photo.url {
                    _ = Photo(title: photo.title, imageUrl: url, forPin: forPin, context: CoreDataManager.shared().context)
                    self.save()
                }
            }
            
        }
        NotificationCenter.default.post(name: .reloadCompleted, object:nil)
        
    }
    
    
    /// Draw the specific pin on the Map
    ///
    /// - Parameter pin: pin entity
    private func showOnTheMap(_ pin: Pin) {
        
        let lat = Double(pin.latitude!)!
        let lon = Double(pin.longitude!)!
        let locCoord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = locCoord
        
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(annotation)
        mapView.setCenter(locCoord, animated: true)
    }
    
    
    /// Load photos from DB and external storage
    ///
    /// - Parameter pin: pin entity
    /// - Returns: list of photos
    private func loadPhotos(using pin: Pin) -> [Photo]? {
        let predicate = NSPredicate(format: "pin == %@", argumentArray: [pin])
        var photos: [Photo]?
        do {
            try photos = CoreDataManager.shared().fetchPhotos(predicate, entityName: Photo.name)
        } catch {
            print("\(#function) error:\(error)")
            showInfoAlert(withTitle: "Error", withMessage: "Error while loading Photos from disk: \(error)")
        }
        return photos
    }
    
    
    /// Update screen on device rotation
    ///
    /// - Parameter withSize: <#withSize description#>
    private func updateFlowLayout(_ withSize: CGSize) {
        
        let landscape = withSize.width > withSize.height
        
        let space: CGFloat = landscape ? 5 : 3
        let items: CGFloat = landscape ? 2 : 3
        
        let dimension = (withSize.width - ((items + 1) * space)) / items
        
        flowLayout?.minimumInteritemSpacing = space
        flowLayout?.minimumLineSpacing = space
        flowLayout?.itemSize = CGSize(width: dimension, height: dimension)
        flowLayout?.sectionInset = UIEdgeInsets(top: space, left: space, bottom: space, right: space)
    }
    
    // MARK: Call UIViewController Extension to lock UI Itens
    private func enableUIControls(_ enable: Bool){
        print("\(#function): , \(enable)")
        self.enableUIItens(views: button, barButton: trashButton, enable:enable)
    }
    
    
    @objc func reloadStarted() {
        self.enableUIControls(false)
    }
    
    @objc func reloadCompleted() {
        self.enableUIControls(true)
    }
    
}

// MARK: - Extensions

extension PhotoAlbumViewController {
    
    // MARK: - MKMapViewDelegates
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
}
