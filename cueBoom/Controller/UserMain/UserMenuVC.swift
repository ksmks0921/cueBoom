//
//  UserMenuVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 6/16/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import SwiftKeychainWrapper

class UserMenuVC: UIViewController {
    
    @IBOutlet weak var navItem: UINavigationItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set left bar button
        let exitBtn = UIBarButtonItem(image: UIImage(named: "exit"), style: .plain, target: self, action: #selector(exitBtnTapped))
        exitBtn.tintColor = .white
        navItem.setLeftBarButton(exitBtn, animated: true)

    }
    
    @objc func exitBtnTapped() {
        //Instantiate Request vc and push
        //TODO: when menu has more options, will have to modify this
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func resetSession(_ sender: Any) {
        userService.shared.currentSession = nil
        let storyboard = UIStoryboard(name: "UserMain", bundle: .main)
        let vc = storyboard.instantiateViewController(withIdentifier: "RequestVC")
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func logoutBtnTapped(_ sender: Any) {
        _ = KeychainWrapper.standard.removeObject(forKey: KEY_UID)
        try! Auth.auth().signOut()
        
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: ["":""])
        
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        
//        InstanceID.instanceID().deleteID { error in
//          if let error = error {
//            print("Error deleting instance ID: \(error)")
//          }
//        }
        
        try? Auth.auth().signOut()
        
        userService.shared.setUser(userUID: "", fcmToken: "", type: "", session: nil, connectID: nil)
        
        performSegue(withIdentifier: "toHome", sender: nil)
    }
    
}
