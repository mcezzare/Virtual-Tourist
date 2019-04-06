//
//  Notifications.swift
//  Virtual Tourist
//
//  Created by Mario Cezzare on 06/04/19.
//  Copyright © 2019 Mario Cezzare. All rights reserved.
//


import UIKit

// MARK: concentrate all Notifications of the app, basicaly to start/stop the status of UIActivityIndicatorView
extension Notification.Name {
    static let reload = Notification.Name("reload")
    static let reloadStarted = Notification.Name("reloadStarted")
    static let reloadCompleted = Notification.Name("reloadCompleted")
}

