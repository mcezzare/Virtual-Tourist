//
//  PhotoViewCell.swift
//  Virtual Tourist
//
//  Created by Mario Cezzare on 05/04/19.
//  Copyright © 2019 Mario Cezzare. All rights reserved.
//


import UIKit

class PhotoViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    static let identifier = "PhotoViewCell"
    var imageUrl: String = ""
    
    // MARK: - Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Methods/Overrides
    
    // To allow multiple selection and mark selected images
    override var isSelected: Bool {
        didSet {
            self.layer.borderWidth = 3.0
            self.layer.borderColor = isSelected ? UIColor.blue.cgColor : UIColor.clear.cgColor
            self.imageView.alpha = isSelected ? 0.3 : 1 // restore to normal state if not selected
        }
    }
}

// MARK: - Extensions

extension PhotoViewCell: UICollectionViewDelegateFlowLayout {
    
    // MARK: - Delegates
    func collectionView(_ collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout,                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let size = CGSize(width: 150, height: 150)
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        
        return 1.0
    }
}
