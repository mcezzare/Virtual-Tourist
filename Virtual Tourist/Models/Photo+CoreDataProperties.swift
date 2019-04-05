//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Mario Cezzare on 05/04/19.
//  Copyright © 2019 Mario Cezzare. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var title: String?
    @NSManaged public var imageUrl: String?
    @NSManaged public var image: NSData?
    @NSManaged public var pin: Pin?

}
