//
//  DJGigInstructionsVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/6/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class DJGigInstructionsVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.customMakeTranslucent()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.customMakeOpaque()
    }

   

}
