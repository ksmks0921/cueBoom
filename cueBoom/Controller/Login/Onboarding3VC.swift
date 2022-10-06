//
//  Onboarding3VC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/20/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit

class Onboarding3VC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
    }

    @IBAction func getStartedBtnTapped(_ sender: Any) {
        performSegue(withIdentifier: "toUser", sender: nil)
    }
    
    
    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        if sender.direction == .right {
            navigationController?.popViewController(animated: true)
        }
        
    }

}
