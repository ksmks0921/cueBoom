//
//  DJSignUpVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 7/15/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import SwiftKeychainWrapper
import GoogleSignIn
import FBSDKLoginKit
import AuthenticationServices


enum LoginType: String {
    case email
    case gmail
    case facebook
    case apple
}

class DJSignUpVC: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var pwdField: UITextField!
    @IBOutlet weak var confirmPwdField: UITextField!
    @IBOutlet weak var dobPicker: UIDatePicker!
    @IBOutlet weak var signUpBtn: UIButton!
    @IBOutlet weak var nameField: DJProfileTextField!
    
    @IBOutlet var loadingView: UIView!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var accountLinkButton: RoundedButton!
    
    var datePicker: UIDatePicker!
    var accountID = ""
    var currentAccountLink = ""
    var fbLoginManager: LoginManager? = nil
    fileprivate var currentNonce: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Create date picker
        datePicker = UIDatePicker(frame: CGRect.zero)
        datePicker.datePickerMode = .date
        datePicker.minimumDate = Date(timeIntervalSince1970: -2208988800) //Jan 1, 1900
        datePicker.maximumDate = Date()
        
        datePicker = UIDatePicker.init(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 200))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func addName(name: String, uid: String) {
        let db = Firestore.firestore()
        db.collection("djs_public").document(uid).setData(["name" : name]) { (err) in
            if err != nil {
                Alerts.errMessage(view: self, message: err!.localizedDescription)
                return
            }
            
            print("Name added")
        }
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
    
    func emailIsValid(_ email: String) -> Bool {
        let emailRegEx = "(?:[a-zA-Z0-9!#$%\\&‘*+/=?\\^_`{|}~-]+(?:\\.[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}"+"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"+"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"+"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"+"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"+"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"+"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        
        let emailTest = NSPredicate(format:"SELF MATCHES[c] %@", emailRegEx)
        
        return emailTest.evaluate(with: email)
    }
    
    func completeSignIn(id: String, email: String, provider: String, completion: @escaping() -> ()) {
        
        //KeychainWrapper.standard.set(id, forKey: KEY_UID)
        //USER_DEFAULTS.set(TYPE_DJ, forKey: TYPE)
        //USER_DEFAULTS.set(id, forKey: KEY_UID)
        
        let djData: [String:Any] = [
            "email": email,
            "provider": provider,
            "uid": id,
            "userType": 0,
            "isVerified": false,
            "approvedByAdmin" : true
        ]
        
        FirestoreService.shared.createDj(uid: id, djData: djData) {
            //Completion
            CloudFunctions.shared.createStripeConnectAccount(uid: id) { (accountID, err) in
                if err != nil {
                    print("Error Creating Stripe Account: \(err!)")
                    return
                }
                
                self.accountID = accountID!
                completion()
            }
        }
    }
    
    func setDataToFirestore(_ userId: String, _ email: String, _ provider: String, _ name: String, _ loginType: LoginType) {
        loadingLabel.text = "Connecting to billing"
        completeSignIn(id: userId, email: email, provider: provider) {
            
            UserDefaults.standard.setValue(true, forKey: APP_FIRSTTIME_OPENED)
            self.addName(name: name, uid: userId)
            self.loadingLabel.text = "Getting account Onboarding Link"
            
            CloudFunctions.shared.welcomeEmail(email: email, name: name) { isSuccess in
                print("isSuccess send welcome email", isSuccess)
            }
            
            CloudFunctions.shared.createAccountLink(accountID: self.accountID) { (url, err)  in
                if err != nil {
                    Alerts.errMessage(view: self, message: err!)
                    self.loadingView.alpha = 0
                    return
                }
                
                self.currentAccountLink = url!
                self.loadingIndicator.stopAnimating()
                self.accountLinkButton.alpha = 1
                Alerts.shared.ok(viewController: self, title: "All set", message: "We are verifying your account and will notify you when ready. For now, start the onBoarding flow so that we can pay you directly to your bank account!")
            }
        }
    }
    
    func signupWithSocial(_ credential: AuthCredential, _ loginType: LoginType, _ appleIDCredential: ASAuthorizationAppleIDCredential? = nil) {
        
        loadingIndicator.startAnimating()
        loadingView.alpha = 1
        accountLinkButton.alpha = 0
        
        Auth.auth().signIn(with: credential) { [self] authResult, error in
            if let error = error {
                loadingView.alpha = 0
                Alerts.shared.ok(viewController: self, title: "Error", message: error.localizedDescription)
            } else {
                let user = authResult!.user
                
                if loginType == .gmail {
                    let displayName = GIDSignIn.sharedInstance.currentUser!.profile!.name
                    let gmail = GIDSignIn.sharedInstance.currentUser!.profile!.email
    //                let hasImage = GIDSignIn.sharedInstance.currentUser!.profile!.hasImage //Bool
    //                let photoUrl = GIDSignIn.sharedInstance.currentUser!.profile!.imageURL(withDimension: 128)! //Foundation.URL
                    
                    setDataToFirestore(user.uid, gmail, user.providerID, displayName, .gmail)
                } else if loginType == .facebook {
                    getFBUserData(user: authResult!.user)
                } else if loginType == .apple {
                    guard let appleIDCredential = appleIDCredential else {return}

                    let userIdentifier  = appleIDCredential.user
                    let fullName        = appleIDCredential.fullName
                    var name            = fullName?.givenName ?? ""
                    if let familyName = fullName?.familyName {
                        name = name == "" ? familyName: name + " " + familyName
                    }
                    
                    var email = appleIDCredential.email ?? ""
                    if email == "" {
                        email =  userIdentifier + "@apple.com"
                    }
                    setDataToFirestore(user.uid, email, user.providerID, name, .apple)
                }
            }
        }
    }
    
    func getFBUserData(user: User){
        if((AccessToken.current) != nil) {
            GraphRequest(graphPath: "me", parameters: ["fields": "id, email, name, first_name, last_name"])
                .start(completion: {[self] (connection, result, error) -> Void in
                
                if (error == nil) {
                    fbLoginManager!.logOut()
                    guard let dict = result as? Dictionary<String, Any> else {return}
                    
                    let email       = dict["email"] as! String
                    let name        = dict["name"] as? String ?? "unknown"
//                    let id          = dict["id"] as! String
//                    let first_name  = dict["first_name"] as? String ?? "unknown"
//                    let last_name   = dict["last_name"] as? String ?? "unknown"
//                    let photoUrl    = "https://graph.facebook.com/" + id + "/picture?type=large"
                    
                    setDataToFirestore(user.uid, email, user.providerID, name, .facebook)
                    fbLoginManager?.logOut()
                } else {
                    loadingView.alpha = 0
                    print(error!)
                }
            })
        } else {
            print("token is null")
        }
    }
    
    @IBAction func signUpBtnTapped(_ sender: Any) {
        self.loadingIndicator.startAnimating()
        self.loadingView.alpha = 1
        self.accountLinkButton.alpha = 0
        
        signUpBtn.isEnabled = false //Disable sign up button on tap.
        
        guard let email = emailField.text, let pwd = pwdField.text, let confirmPwd = confirmPwdField.text else {
            Alerts.shared.ok(viewController: self, title: "Something went wrong", message: "Let's try that one more time.")
            signUpBtn.isEnabled = true //Re-enable
            self.loadingView.alpha = 0
            return
        }
        
        guard signUpInfoIsValid(email: email, pwd: pwd, confirmPwd: confirmPwd) == true else {
            signUpBtn.isEnabled = true //Re-enable
            self.loadingView.alpha = 0
            return
        }
        
        guard nameField.text != nil && nameField.text != "" else {
            Alerts.shared.ok(viewController: self, title: "Something went wrong", message: "Please add a display name. This is what users will see when they visit your profile.")
            signUpBtn.isEnabled = true //Re-enable
            self.loadingView.alpha = 0
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: pwd, completion: { (auth, error) in
            if error != nil {
                self.signUpBtn.isEnabled = true //Re-enable
                
                if error?.localizedDescription == "The email address is already in use by another account." {
                    Alerts.shared.ok(viewController: self, title: "Email already in use", message: "Please sign up with a different email address")
                    self.loadingView.alpha = 0
                } else {
                    Alerts.shared.ok(viewController: self, title: "Email", message: "Please sign up with a valid email address")
                    self.loadingView.alpha = 0
                }
            } else {
                if let auth = auth {
                    let name =  self.nameField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.setDataToFirestore(auth.user.uid, email, auth.user.providerID, name, .email)
                }
            }
        })
    }
    
    @IBAction func goToOnboardingLink(_ sender: Any) {
        if let url = URL(string: self.currentAccountLink) {
            UIApplication.shared.open(url)
            loadingView.alpha = 0
            signUpBtn.isEnabled = true
            navigationController?.popToRootViewController(animated: true)
//            dismiss(animated: true, completion: nil)
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

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [unowned self] user, error in
            if let error = error {
                loadingView.alpha = 0
                Alerts.shared.ok(viewController: self, title: "Something went wrong", message: error.localizedDescription)
                return
            }

            guard let authentication = user?.authentication, let idToken = authentication.idToken else { return }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
            signupWithSocial(credential, .gmail)
        }
    }
    
    @IBAction func didTapFacebook(_ sender: Any) {
        fbLoginManager = LoginManager()
        fbLoginManager!.logIn(permissions: ["public_profile", "email"], from: self) { [self](result, error) in
            if (error == nil){
                guard let accessToken = AccessToken.current else {
                    print("Failed to get access token")
                    return
                }
                
                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)

                signupWithSocial(credential, .facebook)
            } else {
                loadingView.alpha = 0
                print("Login failed")
            }
        }
    }
}


extension DJSignUpVC: ASAuthorizationControllerDelegate {

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
            signupWithSocial(credential, .apple, appleIDCredential)
        } else if let passwordCredential = authorization.credential as? ASPasswordCredential  {
            let username = passwordCredential.user
            let password = passwordCredential.password
            let message = "The app has received your selected credential from the keychain. \n\n Username: \(username)\n Password: \(password)"
            print("message===>", message)

            let alert = UIAlertController(title: "Keychain Credential Received", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))

            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        } else {
            print("-------------------------- apple signin with other options --------------------------")
        }
    }
    

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("Sign in with Apple errored: \(error)")
        loadingView.alpha = 0
//        Alerts.shared.ok(viewController: self, title: "cueBoom", message: error.localizedDescription)
    }
}

extension DJSignUpVC: ASAuthorizationControllerPresentationContextProviding {
    /// - Tag: provide_presentation_anchor
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
