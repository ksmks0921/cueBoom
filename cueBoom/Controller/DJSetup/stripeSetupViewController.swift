//
//  stripeSetupViewController.swift
//  cueBoom
//
//  Created by Charles Oxendine on 5/15/20.
//  Copyright © 2020 CueBoom LLC. All rights reserved.
//

import UIKit

class stripeSetupViewController: UIViewController {

    @IBOutlet weak var dialogueLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var goToSetupButton: RoundedButton!
    @IBOutlet weak var afterCompleteButton: RoundedButton!
    
    var currentAccountLink: String?
    var uid = ""
    var accountID = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.goToSetupButton.alpha = 1
        self.afterCompleteButton.alpha = 0
        
        self.goToSetupButton.isEnabled = false
        setUpStripe()
    }
    
    func setUpStripe() {
        self.loadingIndicator.startAnimating()
        CloudFunctions.shared.createStripeConnectAccount(uid: uid) {[self] (accountID, err) in
            if err != nil {
                print("Error Creating Stripe Account: \(err!)")
                return
            }
            
            self.accountID = accountID!
            
            CloudFunctions.shared.createAccountLink(accountID: accountID!) { (url, err)  in
                if err != nil {
                    loadingIndicator.stopAnimating()
                    return
                }
                
                print(url!)
                currentAccountLink = url!
                
                loadingIndicator.stopAnimating()
                goToSetupButton.isEnabled = true
                dialogueLabel.text = "We need to collect some information in order to pay you out directly. You will be connected to Stripe onboarding that will support our payments. Your information is secure and will never be shared."
            }
        }
    }
    
    @IBAction func goToSetupTapped(_ sender: Any) {
        if let url = URL(string: self.currentAccountLink!) {
            UIApplication.shared.open(url)
            self.loadingIndicator.stopAnimating()
            self.goToSetupButton.alpha = 0
            self.afterCompleteButton.alpha = 1
        }
    }
    
    @IBAction func afterCompleteButtonTapped(_ sender: Any) {
        CloudFunctions.shared.getTransferCapability(connectAccountID: self.accountID, vc: self) { (accountStanding) in
            if accountStanding == false {
                //Show UI Alert telling them they didnt finish setting up
                let storyboard = UIStoryboard(name: "DJSetup", bundle: nil)
                let newVC = storyboard.instantiateViewController(withIdentifier: "stripeSetup") as! stripeSetupViewController
                newVC.uid = self.uid
                newVC.modalPresentationStyle = .fullScreen
                self.present(newVC, animated: true)
                return
            }
            
            //self.performSegue(withIdentifier: "toDJMain", sender: nil)
            Alerts.shared.waitApproveByAdminAndPresent(viewController: self)
        }
    }
}
