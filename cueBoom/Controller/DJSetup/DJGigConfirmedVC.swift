//
//  DJGigConfirmedVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/6/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class DJGigConfirmedVC: UIViewController {

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
