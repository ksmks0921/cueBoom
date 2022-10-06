//
//  DJSetupInstructionsVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/6/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import FirebaseAuth

class DJSetupInstructionsVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateOnboarding()
        USER_DEFAULTS.set(true, forKey: DID_COMPLETE_DJ_ONBOARDING)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.customMakeTranslucent()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.customMakeOpaque()
    }
    
    func updateOnboarding() {
        FirestoreService.shared.updateOnboardingComplete(type: .dj, userUID: Auth.auth().currentUser?.uid ?? "") { (success) in
            if success == true {
                print("Success Update")
                return
            }
        }
    }
}
