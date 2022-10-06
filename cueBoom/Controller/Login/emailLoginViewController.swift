//
//  emailLoginViewController.swift
//  cueBoom
//
//  Created by Charles Oxendine on 12/30/19.
//  Copyright © 2019 CueBoom LLC. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import LocalAuthentication
import Firebase
import GoogleSignIn
import FBSDKLoginKit
import AuthenticationServices


class emailLoginViewController: UIViewController {

    @IBOutlet weak var loginButton: RoundedButton!
    @IBOutlet weak var emailField: CustomTextField!
    @IBOutlet weak var passwordFIeld: CustomTextField!
    @IBOutlet weak var butRememberMe: UIButton!
        
    let db = Firestore.firestore()
    let auth = Auth.auth()
    fileprivate var currentNonce: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let savedCreds = Utilities.checkForKeyChainLogin()
        let email = savedCreds?.0
        let password = savedCreds?.1
        
        if password != nil && email != nil {
            let context = LAContext()
                var error: NSError? = nil
                let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            if canEvaluate {
                if context.biometryType != .none {
                    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "To access your data") { (success, error) in
                        if success {
                            DispatchQueue.main.async {
                                self.emailField.text = email
                                self.passwordFIeld.text = password
                                self.loginButtonTapped(self)
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func validateFields(completion: ( ) -> ()) {
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordFIeld.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard email != nil && password != nil else {
            Alerts.errMessage(view: self, message: "")
            return
        }
        
        if email == "" || password == "" {
            Alerts.errMessage(view: self, message: "Please fill in all fields.")
        } else {
            return
        }
    }
    
    func gotoMainVC(_ auth: AuthDataResult?, _ loginType: LoginType) {
        UserDefaults.standard.setValue(true, forKey: APP_FIRSTTIME_OPENED)
        UserDefaults.standard.setValue(butRememberMe.isSelected, forKey: REMEMBER_ME)
        
        let db = Firestore.firestore()
        db.collection("users_private").document(auth!.user.uid).getDocument { (snap, err) in
            if err != nil {
                Alerts.errMessage(view: self, message: "Error: \(err!.localizedDescription)")
                return
            }
            
            let uid = auth?.user.uid
            let type = snap?.data()?["userType"] as? Int
            
            if type != 1 {
                Alerts.errMessage(view: self, message: "Error: these login credentials might be for a different type of account. If you are a DJ, you can login through your DJ Account in the menu.")
                return
            }
            
            let pushManager = PushNotificationManager(userID: uid!)
            pushManager.registerForPushNotifications(uid: uid!)
            
            userService.shared.setUser(userUID: uid!, fcmToken: notificationServices.shared.fcm_string, type: UserDefaults.standard.string(forKey: "type"), session: Session(), connectID: nil)
            
            userService.shared.type = "user"
            
            let db = Firestore.firestore()
            
            Messaging.messaging().token { (token, error) in
//                InstanceID.instanceID().instanceID { (result, error) in
                if let error = error {
                    print("Error fetching remote token ID: \(error)")
                } else if let token = token {
                    db.collection("users_private").document((auth?.user.uid)!).updateData(["fcmToken" : token]) { (err) in
                        if err != nil {
                            print("Error: \(err!.localizedDescription)")
                            return
                        }
                    }
                }
            }
            
//            Utilities.saveKeychainLoginInfo(email: email!, password: password!)
            
            let storyboard = UIStoryboard(name: "UserSetup", bundle: nil)
            let newVC = storyboard.instantiateViewController(withIdentifier: "navController")
            newVC.modalPresentationStyle = .fullScreen
            self.present(newVC, animated: true)
        }
    }
    
    func loginWithSocial(_ credential: AuthCredential, _ loginType: LoginType) {
        Auth.auth().signIn(with: credential) { [self] authResult, error in
            if let error = error {
                Alerts.shared.ok(viewController: self, title: "Error", message: error.localizedDescription)
            } else {// User is signed in
                gotoMainVC(authResult, loginType)
            }
        }
    }
    
    @IBAction func didTapRememberMe(_ sender: UIButton) {
        sender.isSelected.toggle()
    }
    
    @IBAction func didTapRememberMeText(_ sender: UIButton) {
        butRememberMe.isSelected.toggle()
    }
    
    
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordFIeld.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // MARK: TO DO: HANDLE INPUT FROM USER
        let test_email = "sybellaluna@yahoo.com";
        let test_password = "Goyard2500!";
        auth.signIn(withEmail: test_email, password: test_password) {[self] (auth, err) in
            if err != nil {
                Alerts.errMessage(view: self, message: "Error: \(err!.localizedDescription)")
                return
                //MARK: TO DO: ADD ERROR LABEL
            }
            
            let _ = Utilities.saveKeychainLoginInfo(email: email!, password: password!)
            gotoMainVC(auth, .email)
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
            loginWithSocial(credential, .gmail)
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

                fbLoginManager.logOut()
                loginWithSocial(credential, .facebook)
                
            } else {
                print("Login failed")
            }
        }
    }
    
}


extension emailLoginViewController: ASAuthorizationControllerDelegate {

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
            loginWithSocial(credential, .apple)
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("Sign in with Apple errored: \(error)")
//        Alerts.shared.ok(viewController: self, title: "cueBoom", message: error.localizedDescription)
    }
}

extension emailLoginViewController: ASAuthorizationControllerPresentationContextProviding {
    /// - Tag: provide_presentation_anchor
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
