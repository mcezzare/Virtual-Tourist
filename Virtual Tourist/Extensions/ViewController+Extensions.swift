//
//  ViewController+Extensions.swift
//  Virtual Tourist
//
//  Created by Mario Cezzare on 05/04/19.
//  Copyright © 2019 Mario Cezzare. All rights reserved.
//

import UIKit

extension UIViewController {
    
    var appDelegate: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    func save() {
        do {
            try CoreDataManager.shared().saveContext()
        } catch {
            showInfoAlert(withTitle: "Error", withMessage: "Error while saving Pin location: \(error)")
        }
    }
    
    func showInfoAlert(withTitle: String = "Info", withMessage: String, action: (() -> Void)? = nil) {
        performUIUpdatesOnMain {
            let ac = UIAlertController(title: withTitle, message: withMessage, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: {(alertAction) in
                action?()
            }))
            self.present(ac, animated: true)
        }
    }
    
    func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
        DispatchQueue.main.async {
            updates()
        }
    }
    
    func showConfirmationAlert(withMessage: String, actionTitle: String, action: @escaping () -> Void) {
        performUIUpdatesOnMain {
            let ac = UIAlertController(title: nil, message: withMessage, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            ac.addAction(UIAlertAction(title: actionTitle, style: .destructive, handler: { (alertAction) in
                action()
            }))
            self.present(ac, animated: true)
        }
    }
}



