//
//  LocationInstructionsVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/30/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class LocationInstructionsVC: UIViewController {
    

    override func viewDidLoad() {
        super.viewDidLoad()

        //User has started onboarding process, so onboarding screens should not show up again
        USER_DEFAULTS.set(true, forKey: DID_COMPLETE_GUEST_ONBOARDING)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //Set nav bar translucent for this screen
       navigationController?.customMakeTranslucent()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.customMakeOpaque()
    }
    
    @IBAction func findVenueBtnTapped(_ sender: Any) {
        
    }
}
