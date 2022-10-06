//
//  UserLoginVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/17/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import FirebaseAuth

class UserLoginVC: UIViewController {
    
    @IBOutlet weak var phoneNumberField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        phoneNumberField.keyboardType = .numberPad
        phoneNumberField.becomeFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? SMSVerifyVC {
            if let phoneNumber = sender as? String {
                destination.phoneNumber = phoneNumber
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @IBAction func sendCodeBtnTapped(_ sender: Any) {
        guard var phoneNumber = phoneNumberField.text else {return}
        guard phoneNumber != "", phoneNumber.count == 10 else {
            Alerts.shared.ok(viewController: self, title: "Try again", message: "Please enter a valid phone number!")
            return
        }
        
        view.endEditing(true)
        
        //Add US country code
        phoneNumber = "+1" + phoneNumber
        
        // MARK: ERROR ON LOGIN
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { (verificationID, error) in
            if let error = error {
                Alerts.shared.ok(viewController: self, title: "Oops", message: "Sorry, there was a problem using this phone number. Please check your number and try again.")
                print(error.localizedDescription)
                print("ERROR: \(error)")
                return
            }
            
            guard verificationID != nil else {
                Alerts.shared.ok(viewController: self, title: "Oops", message: "Sorry, there was a problem using this phone number. Please check your number and try again.")
                return
            }
            
            //Add verification id to user defaults so it doesn't get lost when user leaves to check texts and returns to app.
            print(verificationID!)
            NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: notificationServices.shared.fcmToken)
            USER_DEFAULTS.set(verificationID!, forKey: AUTH_VERIFICATION_ID)
            
            self.performSegue(withIdentifier: "toVerify", sender: phoneNumber)
        }
        //self.performSegue(withIdentifier: "toVerify", sender: phoneNumber)
    }

}
