//
//  agreeViewController.swift
//  cueBoom
//
//  Created by Charles Oxendine on 4/24/20.
//  Copyright © 2020 CueBoom LLC. All rights reserved.
//

import UIKit
import FirebaseAuth

class agreeViewController: UIViewController {

    @IBOutlet weak var continueButton: RoundedButton!
    @IBOutlet weak var TermsButton: RoundedButton!
    @IBOutlet weak var checkButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkButtonTapped(self)
        
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
        } else {
            // Fallback on earlier versions
        }
    }
    
    @IBAction func termsButtonTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let newVC = storyboard.instantiateViewController(withIdentifier: "terms")
        self.present(newVC, animated: true)
    }
    
    @IBAction func privacyButtonTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let newVC = storyboard.instantiateViewController(withIdentifier: "privacy")
        self.present(newVC, animated: true)
    }
    
    var checked: Bool = false
    @IBAction func checkButtonTapped(_ sender: Any) {
        if self.checked == false {
            self.continueButton.isEnabled = true
            self.checked = true
            if #available(iOS 13.0, *) {
                self.checkButton.setBackgroundImage(UIImage(systemName: "square"), for: .normal)
                self.continueButton.backgroundColor = .darkGray
                self.continueButton.isEnabled = false
            } else {
                // Fallback on earlier versions
            }
        } else if self.checked == true {
            self.continueButton.isEnabled = false
            self.checked = false
            if #available(iOS 13.0, *) {
                self.checkButton.setBackgroundImage(UIImage(systemName: "checkmark.square"), for: .normal)
                self.continueButton.backgroundColor = TEALISH
                self.continueButton.isEnabled = true
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    @IBAction func continueTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "DJMain", bundle: nil)
        let newVC = storyboard.instantiateViewController(identifier: "GigsVC") as? DJGigsVC
        self.navigationController?.pushViewController(newVC!, animated: true)
    }
}
