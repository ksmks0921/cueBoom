//
//  payoutViewController.swift
//  cueBoom
//
//  Created by Charles Oxendine on 5/4/20.
//  Copyright © 2020 CueBoom LLC. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

protocol payoutViewControllerDelegate: AnyObject {
    func backTapped()
}

class payoutViewController: UIViewController {

    @IBOutlet weak var legalNameField: DJProfileTextField!
    @IBOutlet weak var bankAccountNumberField: DJProfileTextField!
    @IBOutlet weak var bankRoutingNumberField: DJProfileTextField!
    @IBOutlet weak var finalizeRequest: RoundedButton!
    
    @IBOutlet weak var coverLoadingView: UIView!
    
    var email = ""
    var amount: Double!
    
    var delegate: payoutViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addGestureRecognizer(UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:))))
        self.finalizeRequest.isEnabled = true
    }
    
    @IBAction func finalizeRequestTapped(_ sender: Any) {
        self.coverLoadingView.alpha = 1
        let bankAccountNumber = self.bankAccountNumberField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let routingNumber = self.bankRoutingNumberField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let bankName = self.legalNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if bankAccountNumber == "" ||
            bankName == "" ||
            routingNumber == "" {
            errMessage(message: "Please fill in all fields.")
            self.coverLoadingView.alpha = 0
            return
        }
        
        CloudFunctions.shared.addBankAccount(accountID: userService.shared.connectID, routingNumber: routingNumber!, accountNumber: bankAccountNumber!, bankName: bankName!, vc: self) { (confirm) in
            if confirm != nil {
                let alert = UIAlertController(title: "Bank Account Added!", message: nil, preferredStyle: .alert)
                let close = UIAlertAction(title: "Close", style: .default) { (action) in
                    self.delegate?.backTapped()
                    self.navigationController?.popViewController(animated: true)
                }
                alert.addAction(close)
                self.coverLoadingView.alpha = 0
                self.present(alert, animated: true)
            } else {
                self.coverLoadingView.alpha = 0
            }
        }
    }
    
    func errMessage(message: String) {
        
        let alert = UIAlertController(title: "Oops!", message: message, preferredStyle: .alert)
        let close = UIAlertAction(title: "Close", style: .default, handler: nil)
        alert.addAction(close)
        self.present(alert, animated: true)
        
    }
}
