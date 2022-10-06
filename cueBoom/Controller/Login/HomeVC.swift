//
//  HomeVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/17/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import Firebase
import FirebaseFirestore

class HomeVC: UIViewController {
    
    @IBOutlet weak var termsLbl: TermsLabel!
    @IBOutlet weak var coverLoadingView: UIImageView!
    @IBOutlet weak var loadingViewTitle: UILabel!
    @IBOutlet weak var loadingViewTitle2: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        termsLbl.tapDelegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        let appFirstTimeOpend = UserDefaults.standard.value(forKey: APP_FIRSTTIME_OPENED) as? Bool ?? false
        let rememberMe = UserDefaults.standard.value(forKey: REMEMBER_ME) as? Bool ?? false
        if Auth.auth().currentUser != nil && appFirstTimeOpend == true && rememberMe == true{
            getUserType(uid: Auth.auth().currentUser!.uid)
        } else {
            self.coverLoadingView.alpha = 0
            self.loadingViewTitle.alpha = 0
            self.loadingViewTitle2.alpha = 0
            try? Auth.auth().signOut()
            UserDefaults.standard.set(false, forKey: APP_FIRSTTIME_OPENED)
        }
    }
    
    @IBAction func unwindToHomeFromLogout(segue: UIStoryboardSegue) {}
    
    func getUserType(uid: String) {
        let db = Firestore.firestore()
        let closeGroup = DispatchGroup()
        
        closeGroup.enter()
        db.collection("users_private").document(uid).getDocument { (snap, err) in
            if err != nil {
                print("Error getting user object: \(err!.localizedDescription)")
                try? Auth.auth().signOut()
                return
            }
            
            if snap?.exists != true {
                closeGroup.leave()
                return
            } else {
                FirestoreService.shared.checkCompletedOnboardingAndApprovedByAdmin(type: .user, userUID: uid, completion: { (completedOnboarding, approvedByAdmin) in
                    if completedOnboarding == true {
                        Messaging.messaging().token { (token, error) in
                            if let error = error {
                                print("Error fetching remote instance ID: \(error)")
                                try? Auth.auth().signOut()
                                self.coverLoadingView.alpha = 0
                                self.loadingViewTitle.alpha = 0
                                self.loadingViewTitle2.alpha = 0
                            } else if let token = token {
                                print("Remote instance ID token: \(token)")
                                userService.shared.setUser(userUID: uid, fcmToken: token, type: "user", session: nil, connectID: nil)
                                self.performSegue(withIdentifier: "toUserMain", sender: nil)
                                self.coverLoadingView.alpha = 0
                                self.loadingViewTitle.alpha = 0
                                self.loadingViewTitle2.alpha = 0
                            }
                        }
                    } else {
                        Messaging.messaging().token { (token, error) in
                            if let error = error {
                                print("Error fetching remote instance ID: \(error)")
                                try? Auth.auth().signOut()
                                self.coverLoadingView.alpha = 0
                                self.loadingViewTitle.alpha = 0
                                self.loadingViewTitle2.alpha = 0
                            } else if let token = token {
                                print("Remote instance ID token: \(token)")
                                userService.shared.setUser(userUID: uid, fcmToken: token, type: "user", session: nil, connectID: nil)
                                self.performSegue(withIdentifier: "toUserSetup", sender: nil)
                                self.coverLoadingView.alpha = 0
                                self.loadingViewTitle.alpha = 0
                                self.loadingViewTitle2.alpha = 0
                            }
                        }
                    }
                })
            }
        }
        
        closeGroup.enter()
        db.collection("djs_private").document(uid).getDocument { (snap, err) in
            if err != nil {
                print("Error getting user object: \(err!.localizedDescription)")
                try? Auth.auth().signOut()
                return
            }
            
            if snap?.exists != true {
                closeGroup.leave()
                return
            } else {
                FirestoreService.shared.checkCompletedOnboardingAndApprovedByAdmin(type: .dj, userUID: uid) { (completedOnboarding, approvedByAdmin) in
                    if completedOnboarding == true {
                        if !approvedByAdmin {
                            Alerts.shared.waitApproveByAdminAndLogout(viewController: self)
                            return
                        }
                        
                        Messaging.messaging().token { (token, error) in
                            if let error = error {
                                print("Error fetching remote instance ID: \(error)")
                            } else if let token = token {
                                FirestoreService.shared.getStripeID(viewController: self, uid: uid) { (connectID, err) in
                                    userService.shared.setUser(userUID: uid, fcmToken: token, type: "user", session: nil, connectID: connectID)
                                    
                                    CloudFunctions.shared.getTransferCapability(connectAccountID: connectID!, vc: self) { (accountStanding) in
                                        if accountStanding == false {
                                            let storyboard = UIStoryboard(name: "DJSetup", bundle: nil)
                                            let newVC = storyboard.instantiateViewController(withIdentifier: "stripeSetup") as! stripeSetupViewController
                                            newVC.uid = uid
                                            newVC.modalPresentationStyle = .fullScreen
                                            self.present(newVC, animated: true)
                                            return
                                        }
                                        
                                        self.performSegue(withIdentifier: "toDJMain", sender: nil)
                                    }
                                }
                            }
                        }
                    } else {
                        Messaging.messaging().token { (token, error) in
                            if let error = error {
                                print("Error fetching remote instance ID: \(error)")
                            } else if let token = token {
                                FirestoreService.shared.getStripeID(viewController: self, uid: uid) { (connectID, err) in
                                    userService.shared.setUser(userUID: uid, fcmToken: token, type: "user", session: nil, connectID: nil)
                                    CloudFunctions.shared.getTransferCapability(connectAccountID: connectID!, vc: self) { (accountStanding) in
                                        if accountStanding == false {
                                            let storyboard = UIStoryboard(name: "DJSetup", bundle: nil)
                                            let newVC = storyboard.instantiateViewController(withIdentifier: "stripeSetup") as! stripeSetupViewController
                                            newVC.uid = uid
                                            newVC.modalPresentationStyle = .fullScreen
                                            self.present(newVC, animated: true)
                                            return
                                        }
                                        
                                        self.performSegue(withIdentifier: "toDJSetup", sender: nil)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        closeGroup.notify(queue: .main) {
            print("THERE ARE NO ACCOUNTS FOUND FOR THIS USER...")
            
            self.coverLoadingView.alpha = 0
            self.loadingViewTitle.alpha = 0
            self.loadingViewTitle2.alpha = 0
            try? Auth.auth().signOut()
        }
    }
}

extension HomeVC: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        print(URL.absoluteString)
        
        return true;
    }
}

extension HomeVC: TermsLabelDelegate {
    
    func labelWasTappedForUsername(_ substring: String) {
        if substring == "Terms of Use" {
            performSegue(withIdentifier: "HomeToTermsOfUse", sender: nil)
        }
        
        if substring == "Privacy Policy" {
            performSegue(withIdentifier: "HomeToPrivacyPolicy", sender: nil)
        }
    }
}


