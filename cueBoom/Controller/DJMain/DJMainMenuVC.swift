//
//  DJMainMenu.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/4/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import SwiftKeychainWrapper
import MessageUI

class DJMainMenuVC: UIViewController {
    
    @IBOutlet weak var paymentButton: UIButton!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var gigsButton: UIButton!
    @IBOutlet weak var logOutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        formatView()
        addToStack()
    }
    
    func addToStack() {
        guard let vcs = navigationController?.viewControllers, let firstVC = vcs.first, !firstVC.isKind(of: DJGigsVC.self) else {return}
        let storyboard = UIStoryboard(name: "DJMain", bundle: .main)
        let mainMenuVC = storyboard.instantiateViewController(withIdentifier: "GigsVC")
        navigationController?.viewControllers.insert(mainMenuVC, at: 0)
    }
    
    func formatView() {
        self.view.bringSubviewToFront(paymentButton)
        self.view.bringSubviewToFront(profileButton)
        self.view.bringSubviewToFront(gigsButton)
        self.view.bringSubviewToFront(logOutButton)
    }
    
    @IBAction func gigsBtnTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "DJMain", bundle: .main)
        let vc = storyboard.instantiateViewController(withIdentifier: "GigsVC")
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func logoutBtnTapped(_ sender: Any) {
        _ = KeychainWrapper.standard.removeObject(forKey: KEY_UID)
        try! Auth.auth().signOut()
    
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        
        try? Auth.auth().signOut()
        
        userService.shared.setUser(userUID: "", fcmToken: "", type: "", session: Session(), connectID: nil)
        
        performSegue(withIdentifier: "logout", sender: nil)
    }
    
    @IBAction func joinAsUserTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let newVC = storyboard.instantiateViewController(withIdentifier: "phoneLogin") as! UserLoginVC
//        newVC.modalPresentationStyle = .fullScreen
//        self.present(newVC, animated: true)
        
        navigationController?.pushViewController(newVC, animated: true)
    }
}

extension DJMainMenuVC: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ didFinishWithcontroller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        self.dismiss(animated: true, completion: nil)
    }
}
