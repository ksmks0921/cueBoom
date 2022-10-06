
//
//  ResetPasswordVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 7/15/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import FirebaseAuth

class ResetPasswordVC: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var resetPasswordBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Keyboard will show notif
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        //Email keyboard
        emailField.keyboardType = .emailAddress
        
        //"Done" button above keyboard
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let postButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneTapped))
        toolBar.setItems([postButton], animated: true)
        emailField.inputAccessoryView = toolBar
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    //Keyboard "done" selector
    @objc func doneTapped() {
        view.endEditing(true)
    }
    
    @IBAction func resetPasswordBtnTapped(_ sender: Any) {
        guard let email = emailField.text else {return}
        guard email != "" else {return}
        
        //Check if email is registered with the app
        //If arr is not empty, email exists. Send password reset email.
        //Else, email is not registered. Don't send password resset email.
        Auth.auth().fetchSignInMethods(forEmail: email) {(arr, error) in
            if error != nil {
                Alerts.shared.ok(viewController: self, title: "Invalid Email", message: "Please try again with a valid email.")
            } else if arr == nil {
                Alerts.shared.ok(viewController: self, title: "Email not registered", message: "Sorry, we don't recognize that email.")
            } else {
                Auth.auth().sendPasswordReset(withEmail: email, completion: { (error) in
                    if error != nil {
                        Alerts.shared.ok(viewController: self, title: "Something went wrong", message: "Sorry about that. Let's try it one more time.")
                    } else {
                        Alerts.shared.ok(viewController: self, title: "Check your inbox", message: "We've sent you instructions on how to reset your password.")
                    }
                })
            }
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            
            if self.view.frame.origin.y == 0 {
                let frameBottom = view.frame.origin.y + view.frame.height
                let resetPasswordBtnBottom = resetPasswordBtn.frame.origin.y + resetPasswordBtn.frame.height
                
                if (view.frame.height - keyboardHeight) < (resetPasswordBtnBottom) {
                    let shiftDistance = resetPasswordBtnBottom - (view.frame.height - keyboardHeight)
                    view.frame.origin.y -= shiftDistance
                }
            }
            
        }
    }
    
    


}
