//
//  SMSVerifyVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/17/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import FirebaseAuth
import SwiftKeychainWrapper
import FirebaseFirestore

class SMSVerifyVC: UIViewController {
    @IBOutlet weak var codeField: UITextField!
    
    //Note: phone number already has "+1" pushed to front of string
    private var _phoneNumber: String!
    var phoneNumber: String {
        get {
            return _phoneNumber
        } set {
            _phoneNumber = newValue
        }
    }
    
    var verificationID: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //"Login" button above keyboard
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: #selector(loginTapped))
        let postButton = UIBarButtonItem(title: "Login", style: .plain, target: self, action: #selector(loginTapped))
        postButton.tintColor = UIColor.white
        toolBar.setItems([flexibleSpace, postButton, flexibleSpace], animated: true)
        toolBar.barTintColor = UIColor.red
        codeField.inputAccessoryView = toolBar
        
        codeField.keyboardType = .numberPad
        codeField.becomeFirstResponder()

        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        codeField.becomeFirstResponder()
    }
    
    @objc func loginTapped() {
        var djUID = userService.shared.uid
        
        guard let code = codeField.text, USER_DEFAULTS.string(forKey: AUTH_VERIFICATION_ID) != nil else {return}
        
        view.endEditing(true)
    
        verificationID = USER_DEFAULTS.string(forKey: AUTH_VERIFICATION_ID)!
        
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: code)
        
        Auth.auth().signIn(with: credential) { (user, error) in
            if let error = error {
                print(error.localizedDescription)
                Alerts.shared.ok(viewController: self, title: "Invalid Code", message: "Check your code and try again, or resend a new code.")
                return
            }
            
            if let user = user {
                
                //Add uid to the keychain
                KeychainWrapper.standard.set(user.user.uid, forKey: KEY_UID)
                USER_DEFAULTS.set(TYPE_USER, forKey: TYPE)
                
                userService.shared.setUser(userUID: user.user.uid, fcmToken: notificationServices.shared.fcm_string, type: UserDefaults.standard.string(forKey: "type"), session: Session(), connectID: nil)

                //Create user
                let userData: [String:Any] = [
                    "userType": 1,
                    "fcmToken": UserDefaults.standard.string(forKey: FCM_TOKEN) ?? "",
                    "isDJ": djUID
                ]
                FirestoreService.shared.createUser(uid: user.user.uid, userData: userData) { (err) in
                    if USER_DEFAULTS.bool(forKey: DID_COMPLETE_GUEST_ONBOARDING) {
                        self.performSegue(withIdentifier: "toUserMain", sender: nil)
                    } else {
                        self.performSegue(withIdentifier: "toUserSetup", sender: nil)
                    }
                }
            } else {
                Alerts.shared.ok(viewController: self, title: "Something went wrong", message: "Please resend code and try again")
            }
            
        }
        
        self.performSegue(withIdentifier: "toUserMain", sender: nil)
    }
    
    
    @IBAction func resendCodeBtnTapped(_ sender: Any) {
        guard _phoneNumber != nil else {return}
        
        PhoneAuthProvider.provider().verifyPhoneNumber(_phoneNumber, uiDelegate: nil) { (verificationID, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            USER_DEFAULTS.set(verificationID, forKey: AUTH_VERIFICATION_ID)
        }
    }
}
