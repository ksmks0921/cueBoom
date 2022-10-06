//
//  Alerts.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/16/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import FirebaseAuth

class Alerts {
    
    static let shared = Alerts()
    
    func ok(viewController: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        viewController.present(alert, animated: true, completion: nil)
    }
    
    func okWithCompletionHandler(viewController: UIViewController, title: String, message: String, completion: @escaping() -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            
            completion()
        }))
        
        viewController.present(alert, animated: true, completion: nil)
    }
    
    func waitApproveByAdminAndPresent(viewController: UIViewController) {
        let title = "Request Account Review"
        let message = "cueBoom is reviewing your account, it can take up to 3~5 days for check yoru account by Manager."
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            let newVC = storyboard.instantiateViewController(withIdentifier: "LoginRoot")
            newVC.modalPresentationStyle = .fullScreen
            viewController.present(newVC, animated: true)
        }))
        
        viewController.present(alert, animated: true, completion: nil)
    }
    
    func waitApproveByAdminAndLogout(viewController: UIViewController) {
        let title = "Request Account Review"
        let message = "cueBoom is reviewing your account, it can take up to 3~5 days for check yoru account by Manager."
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Login with Other", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            
            try! Auth.auth().signOut()
            
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            let newVC = storyboard.instantiateViewController(withIdentifier: "LoginRoot")
            newVC.modalPresentationStyle = .fullScreen
            viewController.present(newVC, animated: true)
        }))
        
        viewController.present(alert, animated: true, completion: nil)
    }
    
    func standardAlert(vc: UIViewController, title: String, message: String, negativeOption: String, affirmativeOption: String, completion: @escaping(Bool) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: negativeOption, style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            completion(false)
        }))
        
        alert.addAction(UIAlertAction(title: affirmativeOption, style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            completion(true)
        }))
        
        vc.present(alert, animated: true, completion: nil)
    }
    
    static func errMessage(view: UIViewController, message: String) {
        var alert = UIAlertController(title: "Error!", message: message, preferredStyle: .alert)
        var close = UIAlertAction(title: "Close", style: .default) { (alert) in
            //close menu
        }
        
        alert.addAction(close)
        view.present(alert, animated: true)
    }
}
