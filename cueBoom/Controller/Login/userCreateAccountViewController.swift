//
//  userCreateAccountViewController.swift
//  cueBoom
//
//  Created by Charles Oxendine on 4/16/20.
//  Copyright © 2020 CueBoom LLC. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import GoogleSignIn
import FBSDKLoginKit
import AuthenticationServices


class userCreateAccountViewController: UIViewController {

    @IBOutlet weak var signUpButton: RoundedButton!
    @IBOutlet weak var emailField: DJProfileTextField!
    @IBOutlet weak var pwdField: DJProfileTextField!
    @IBOutlet weak var confirmPassword: DJProfileTextField!
    fileprivate var currentNonce: String?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func signUpInfoIsValid(email: String, pwd: String, confirmPwd: String) -> Bool {
        
        //Fields are not empty
        guard email != "", pwd != "", confirmPwd != "" else {
            Alerts.shared.ok(viewController: self, title: "Hold up", message: "Please complete all fields before continuing")
            return false
        }
        
        //Email is valid format
        guard emailIsValid(email) else {
            Alerts.shared.ok(viewController: self, title: "Email", message: "Please sign up with a valid email.")
            return false
        }
        
        //Pwd is at least 6 characters
        guard pwd.count >= 6 else {
            Alerts.shared.ok(viewController: self, title: "Password", message: "Password must contain at least 6 characters")
            return false
        }
        
        //Passwords match
        guard pwd == confirmPwd else {
            Alerts.shared.ok(viewController: self, title: "Password", message: "Passwords do not match")
            return false
        }
    
        return true
    }
    
    func isDobValid(_ dob: Date) -> Bool {
        let now = Date()
        let gregorian = Calendar(identifier: .gregorian)
        let components = gregorian.dateComponents([.year], from: dob, to: now)

        guard let age = components.year else {
            return false
        }
    
        if age < 18 {
            return false
        } else {
            return true
        }
    }
    
    func emailIsValid(_ email: String) -> Bool {
        let emailRegEx = "(?:[a-zA-Z0-9!#$%\\&‘*+/=?\\^_`{|}~-]+(?:\\.[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}"+"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"+"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"+"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"+"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"+"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"+"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        
        let emailTest = NSPredicate(format:"SELF MATCHES[c] %@", emailRegEx)
        
        return emailTest.evaluate(with: email)
    }
    
    func signupWithSocial(_ credential: AuthCredential, _ loginType: LoginType) {
        Auth.auth().signIn(with: credential) { [self] authResult, error in
            if let error = error {
                Alerts.shared.ok(viewController: self, title: "Error", message: error.localizedDescription)
            } else {// User is signed in
                let user = authResult!.user
                gotoUserSetupVC(user.uid)                
            }
        }
    }
    
    func gotoUserSetupVC(_ userID: String) {
        let userData: [String:Any] = [
            "fcmToken": notificationServices.shared.fcm_string,
            "userType": 1,
        ]
        
        FirestoreService.shared.createUser(uid: userID, userData: userData) { (err) in
            if err != nil {
                Alerts.shared.ok(viewController: self, title: "Error creating account", message: err!)
            }
            
            userService.shared.setUser(userUID: userID, fcmToken: notificationServices.shared.fcm_string, type: "user", session: nil, connectID: nil)
            
            UserDefaults.standard.setValue(true, forKey: APP_FIRSTTIME_OPENED)
            let storyboard = UIStoryboard(name: "UserSetup", bundle: nil)
            let newVC = storyboard.instantiateViewController(withIdentifier: "navController")
            newVC.modalPresentationStyle = .fullScreen
            self.present(newVC, animated: true)
        }
    }
    
    @IBAction func signUpButtonTapped(_ sender: Any) {
        signUpButton.isEnabled = false //Disable sign up button on tap.
        
        guard let email = emailField.text, let pwd = pwdField.text, let confirmPwd = confirmPassword.text else {
            Alerts.shared.ok(viewController: self, title: "Something went wrong", message: "Let's try that one more time.")
            signUpButton.isEnabled = true //Re-enable
            return
        }
        
        guard signUpInfoIsValid(email: email, pwd: pwd, confirmPwd: confirmPwd) == true else {
            signUpButton.isEnabled = true //Re-enable
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: pwd, completion: {[self] (auth, error) in
            if error != nil {
                self.signUpButton.isEnabled = true //Re-enable
                
                if error?.localizedDescription == "The email address is already in use by another account." {
                    Alerts.shared.ok(viewController: self, title: "Email already in use", message: "Please sign up with a different email address")
                } else {
                    Alerts.shared.ok(viewController: self, title: "Email", message: "Please sign up with a valid email address")
                }
            } else {
                print("SHAHIN: Successfully authenticated with Firebase")
                if let auth = auth {
                    gotoUserSetupVC(auth.user.uid)
                }
            }
        })
    }
    
    @IBAction func aboutUsTapped(_ sender: Any) {
        if let url = URL(string: "https://www.cueboom.com") {
            UIApplication.shared.open(url)
        }
    }

    @IBAction func didTapApple(_ sender: Any) {
        currentNonce = Utilities.randomNonceString()
        let request = Utilities.getAppleIDProviderRequest(nonce: currentNonce!)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    @IBAction func didTapGmail(_ sender: Any) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)

        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [unowned self] user, error in

            if let error = error {
                Alerts.shared.ok(viewController: self, title: "cueBoom", message: error.localizedDescription)
                return
            }

            guard let authentication = user?.authentication, let idToken = authentication.idToken else { return }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
            signupWithSocial(credential, .gmail)
        }
    }
    
    @IBAction func didTapFacebook(_ sender: Any) {
        let fbLoginManager = LoginManager()
        fbLoginManager.logIn(permissions: ["public_profile", "email"], from: self) { [self](result, error) in
            if (error == nil){
                guard let accessToken = AccessToken.current else {
                    print("Failed to get access token")
                    return
                }
                
                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
                signupWithSocial(credential, .facebook)
                fbLoginManager.logOut()
            } else {
                print("Login failed")
            }
        }
    }
}

extension userCreateAccountViewController: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            // Initialize a Firebase credential.
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
            // Sign in with Firebase.
            signupWithSocial(credential, .apple)
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("Sign in with Apple errored: \(error)")
//        Alerts.shared.ok(viewController: self, title: "cueBoom", message: error.localizedDescription)
    }
}

extension userCreateAccountViewController: ASAuthorizationControllerPresentationContextProviding {
    /// - Tag: provide_presentation_anchor
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
