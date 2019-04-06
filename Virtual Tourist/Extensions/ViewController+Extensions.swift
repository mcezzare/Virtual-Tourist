//
//  ViewController+Extensions.swift
//  Virtual Tourist
//
//  Created by Mario Cezzare on 05/04/19.
//  Copyright © 2019 Mario Cezzare. All rights reserved.
//

import UIKit

extension UIViewController {
    
    // MARK: - Properties
    var appDelegate: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    
    /// Shortcut to call Save Context Operations from View Controllers
    func save() {
        do {
            try CoreDataManager.shared().saveContext()
        } catch {
            showInfoAlert(withTitle: "Error", withMessage: "Error while saving Pin location: \(error)")
        }
    }
    
    
    /// Show an alert dialog
    ///
    /// - Parameters:
    ///   - withTitle: Title from alert message
    ///   - withMessage: Text message to appear
    ///   - action: Here only OK option
    func showInfoAlert(withTitle: String = "Info", withMessage: String, action: (() -> Void)? = nil) {
        performUIUpdatesOnMain {
            let ac = UIAlertController(title: withTitle, message: withMessage, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: {(alertAction) in
                action?()
            }))
            self.present(ac, animated: true)
        }
    }
    
    
    /// Show an confirmation action alert dialog
    ///
    /// - Parameters:
    ///   - withTitle: Title from alert message
    ///   - withMessage: Text message to appear
    ///   - action: closure to run if user no choose the cancel option
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
    
    
    /// GCD to back to main thread and update screen
    ///
    /// - Parameter updates: closure to call screen updates
    func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
        DispatchQueue.main.async {
            updates()
        }
    }
    
    // MARK: Lock or Unlock UI Itens when do background tasks
    func enableUIItens(views:UIControl..., barButton: UIBarButtonItem, enable:Bool){
        performUIUpdatesOnMain{
            for view in views{
                view.isEnabled = enable
            }
            
            barButton.isEnabled = enable
            
        }
    }
}
