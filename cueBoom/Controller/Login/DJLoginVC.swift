//
//  DJLoginVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/16/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import Firebase
import GoogleSignIn
import FBSDKLoginKit
import AuthenticationServices

class DJLoginVC: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginBtn: UIButton!
  
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var loadingLogin: UIActivityIndicatorView!
    @IBOutlet weak var loadingText: UILabel!
    @IBOutlet weak var butRememberMe: UIButton!
    
    var uid = ""
    fileprivate var currentNonce: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    
    func areFieldsValid(email: String, password: String) -> Bool {
        
        if email.filter({$0 != " "}) != "", password.filter({$0 != " "}) != "" {
            return true
        } else {
            return false
        }
    }
    
    //Fetches dj_private data and checks if isVerified field is true
    //Will return false if isVerified is false
    //Returns true if 1) isVerified is true, or 2) isVerified field does not exist
    func isDjVerified(uid: String, completion: @escaping(Bool) -> Void) {
        FirestoreService.shared.REF_DJS_PRIVATE.document(uid).getDocument { (snapshot,error) in
            guard error == nil else {
                return completion(false)
            }
            
            guard let data = snapshot?.data() else {
                return completion(false)
            }
            
            guard let isVerified = data["isVerified"] as? Bool else {
                return completion(true)
            }
            
            completion(isVerified)
        }
    }

    func setDJName(uid: String, completion: @escaping() -> Void) {
        let db = Firestore.firestore()
        db.collection("djs_public").document(uid).getDocument { (snapshot, error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                return
            }
            
            let data = snapshot?.data()
            
            if data?["name"] != nil {
                let name = data?["name"] as! String
                userService.shared.name = name
                UserDefaults.standard.setValue(name, forKey: DJ_NAME)
            }
            
            completion()
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
    
    func gotoMainVC(_ auth: AuthDataResult!, _ loginType: LoginType) {
        
        UserDefaults.standard.setValue(true, forKey: APP_FIRSTTIME_OPENED)
        UserDefaults.standard.setValue(butRememberMe.isSelected, forKey: REMEMBER_ME)
        
        let db = Firestore.firestore()
        print("UID: \(auth.user.uid)")
        db.collection("djs_private").document(auth.user.uid).getDocument { (snap, err) in
            if err != nil {
                Alerts.errMessage(view: self, message: "Error: \(err!.localizedDescription)")
                self.loginBtn.isEnabled = true
                try? Auth.auth().signOut()
                self.coverView.alpha = 0
                return
            }
            
            let type = snap?.data()?["userType"] as? Int
            
            if type != 0 {
                Alerts.errMessage(view: self, message: "Error: these login credentials seem to be for a different type of account. Go back and try logging in as a user. ")
                try? Auth.auth().signOut()
                self.loginBtn.isEnabled = true
                self.coverView.alpha = 0
                return
            }
        
            self.uid = auth.user.uid
            
            self.loadingText.text = "Checking if verified..."
            self.isDjVerified(uid: auth.user.uid) { isVerified in
                if isVerified {
                    NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: notificationServices.shared.fcmToken)
                    
                    //Store uid in keychain of device
                    KeychainWrapper.standard.set(auth.user.uid, forKey: KEY_UID)
                    USER_DEFAULTS.set(TYPE_DJ, forKey: TYPE)
                    
                    //Store email in firestore
                    //MARK: EVENTUALLY WANNA ELIMINATE ALL THIS USER DEFAULT STUFF
                    UserDefaults.standard.set(auth.user.uid, forKey: KEY_UID)
                    UserDefaults.standard.set("dj", forKey: "type")
                    userService.shared.type = "dj"
                    
                    self.loadingText.text = "Getting Stripe Info"
                    FirestoreService.shared.getStripeID(viewController: self, uid: auth.user.uid) { (connectID, err) in
                        if err != nil {
                            print("getStripeID error: \(err!)")
                            self.coverView.alpha = 0
                            return
                        }
                        
                        let userUID = auth.user.uid
                        let pushManager = PushNotificationManager(userID: userUID)
                        pushManager.registerForPushNotifications(uid: userUID)
                        
                        userService.shared.setUser(userUID: auth.user.uid, fcmToken: UserDefaults.standard.string(forKey: "fcmToken"), type: "dj", session: Session(), connectID: connectID)
                        
                        CloudFunctions.shared.getTransferCapability(connectAccountID: connectID!, vc: self) { (accountStanding) in
                            self.setDJName(uid: auth.user.uid, completion: {
                                
                                if accountStanding == nil {
                                    Alerts.errMessage(view: self, message: "Error getting stripe capabilities. Please try again and contact customer support if the issue persists.")
                                    return
                                }
                                
                                self.loadingText.text = "Setting Notifications"
                                
                                if accountStanding == false {
                                    let storyboard = UIStoryboard(name: "DJSetup", bundle: nil)
                                    let newVC = storyboard.instantiateViewController(withIdentifier: "stripeSetup") as! stripeSetupViewController
                                    newVC.uid = self.uid
                                    newVC.modalPresentationStyle = .fullScreen
                                    self.present(newVC, animated: true)
                                    return
                                }
                                
                                FirestoreService.shared.checkCompletedOnboardingAndApprovedByAdmin(type: .dj, userUID: userUID) { (onboardingComplete, approvedByAdmin) in
                                    if onboardingComplete {
                                        if approvedByAdmin {
                                            self.performSegue(withIdentifier: "toDJMain", sender: nil)
                                        } else {
                                            Alerts.shared.waitApproveByAdminAndPresent(viewController: self)
                                        }
                                    } else {
                                        self.performSegue(withIdentifier: "toDJSetup", sender: nil)
                                    }
                                }
                            })
                        }
                    }
                } else {
                    
                    Alerts.shared.ok(viewController: self, title: "", message: "We are currently verifying your account. We will notify you when it's ready.")
                    self.loginBtn.isEnabled = true
                    self.coverView.alpha = 0
                }
            }
        }
        
    }
    
    @IBAction func didTapRememberMe(_ sender: UIButton) {
        sender.isSelected.toggle()
    }
    
    @IBAction func didTapRememberMeText(_ sender: Any) {
        butRememberMe.isSelected.toggle()
    }
    
    @IBAction func loginBtnTapped(_ sender: Any) {
        self.loadingLogin.startAnimating()
        self.coverView.alpha = 1
        guard let email = emailField.text, let password = passwordField.text else {
            self.coverView.alpha = 0
            return
        }
        
        guard areFieldsValid(email: email, password: password) else {
            Alerts.shared.ok(viewController: self, title: "Missing email or password", message: "Please enter both to login.")
            self.coverView.alpha = 0
            return
        }
    
        loginBtn.isEnabled = false
        view.endEditing(true)
        
        Auth.auth().signIn(withEmail: email, password: password, completion: {[self] (auth, error) in
            guard error == nil, let auth = auth else {
                Alerts.shared.ok(viewController: self, title: "Invalid email or password", message: "Please try again.")
                self.loginBtn.isEnabled = true
                self.coverView.alpha = 0
                return
            }
            
            gotoMainVC(auth, .email)
        })
    }

    @IBAction func contactBtnTapped(_ sender: Any) {
        
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
                print("fb token is ____" + accessToken.tokenString)
                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)

                loginWithSocial(credential, .facebook)
                fbLoginManager.logOut()
            } else {
                print("Login failed")
            }
        }
    }
    
}


extension DJLoginVC: ASAuthorizationControllerDelegate {

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

extension DJLoginVC: ASAuthorizationControllerPresentationContextProviding {
    /// - Tag: provide_presentation_anchor
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
