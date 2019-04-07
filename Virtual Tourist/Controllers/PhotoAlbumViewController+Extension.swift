//
//  PhotoAlbumViewController+Extension.swift
//  Virtual Tourist
//
//  Created by Mario Cezzare on 05/04/19.
//  Copyright © 2019 Mario Cezzare. All rights reserved.
//


import UIKit
import CoreData

// MARK: - Extension for FRC
extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    // MARK: - Delegates for FRC
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
    }
    
    func controller( _ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch (type) {
        case .insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .update:
            updatedIndexPaths.append(indexPath!)
            break
        case .move:
            print("Not used in this application.")
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({() -> Void in
            NotificationCenter.default.post(name: .reloadStarted, object:nil)
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath])
            }
            
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath])
            }
            
            //           }, completion: nil)
        }, completion:{(result:Bool) in
            if result {
                NotificationCenter.default.post(name: .reloadCompleted, object:nil)
            }
        }
        )
    }
    
}

// MARK: - Extension for UICollectionView

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK: - UICollectionView DataSources
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sectionInfo = self.fetchedResultsController.sections?[section] {
            return sectionInfo.numberOfObjects
        }
        
        return 0
    }
    
    // MARK: - UICollectionView Delegates
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoViewCell.identifier, for: indexPath) as! PhotoViewCell
        cell.imageView.image = nil
        cell.activityIndicator.startAnimating()
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let photo = fetchedResultsController.object(at: indexPath)
        let photoViewCell = cell as! PhotoViewCell
        photoViewCell.imageUrl = photo.imageUrl!
        configureImagesForDisplay(using: photoViewCell, photo: photo, collectionView: collectionView, index: indexPath)
    }
    
    // To select itens and then to delete images
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.allowsMultipleSelection = true
        self.selectedIndexes.append(indexPath)
        debugPrint("adding \(indexPath)")
    }
    
    // To avoid remove itens unselected
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        for (index,value) in self.selectedIndexes.enumerated() {
            if value == indexPath {
                //                print("found at \(index) position")
                self.selectedIndexes.remove(at: index)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying: UICollectionViewCell, forItemAt: IndexPath) {
        
        if collectionView.cellForItem(at: forItemAt) == nil {
            return
        }
        
        let photo = fetchedResultsController.object(at: forItemAt)
        if let imageUrl = photo.imageUrl {
            Client.shared().cancelDownload(imageUrl)
        }
    }
    
    // MARK: - Helpers
    
    private func configureImagesForDisplay(using cell: PhotoViewCell, photo: Photo, collectionView: UICollectionView, index: IndexPath) {
        if let imageData = photo.image {
            cell.activityIndicator.stopAnimating()
            cell.imageView.image = UIImage(data: Data(referencing: imageData))
        } else {
            if let imageUrl = photo.imageUrl {
                cell.activityIndicator.startAnimating()
                Client.shared().downloadImage(imageUrl: imageUrl) { (data, error) in
                    //                NotificationCenter.default.post(name: .reloadStarted, object:nil)
                    if let _ = error {
                        self.performUIUpdatesOnMain {
                            cell.activityIndicator.stopAnimating()
                            self.displayErrorForImageURL(imageUrl)
                        }
                        return
                    } else if let data = data {
                        self.performUIUpdatesOnMain {
                            
                            if let currentCell = collectionView.cellForItem(at: index) as? PhotoViewCell {
                                if currentCell.imageUrl == imageUrl {
                                    currentCell.imageView.image = UIImage(data: data)
                                    cell.activityIndicator.stopAnimating()
                                }
                            }
                            photo.image = NSData(data: data)
                            DispatchQueue.global(qos: .background).async {
                                self.save()
                            }
                        }
                    }
                    //                    NotificationCenter.default.post(name: .reloadCompleted, object:nil)
                }
            }
        }
    }
    
    
    /// Show an alert in case of valid URL and invalid resource
    ///
    /// - Parameter imageUrl: string for a image URL
    private func displayErrorForImageURL(_ imageUrl: String) {
        if !self.displayAlertForInvalidImages {
            self.showInfoAlert(withTitle: "Error", withMessage: "Error while fetching image for URL: \(imageUrl)", action: {
                self.displayAlertForInvalidImages = false
            })
        }
        self.displayAlertForInvalidImages = true
    }
    
}

