//
//  SignOutVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/18/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import FirebaseAuth


class SignOutVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func signOutBtnTapped(_ sender: Any) {
        _ = KeychainWrapper.standard.removeObject(forKey: KEY_UID)
        try! Auth.auth().signOut()
        
        dismiss(animated: true, completion: nil)
    }
}
