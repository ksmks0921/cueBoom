//
//  CloudFunctions.swift
//  cueBoom
//
//  Created by CueBoom LLC on 6/11/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import Foundation
import Alamofire
import SwiftKeychainWrapper
import FirebaseFirestore

class CloudFunctions {
    
    private init() {}
    static let shared = CloudFunctions()
    
    func getCurrentSession(completion: @escaping(Session?) -> Void) {
        let uid = userService.shared.uid
        let url = "https://us-central1-cueboom-46a61.cloudfunctions.net/getCurrentSession"
        let parameters: [String:Any] = ["uid": uid]
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: [:]).responseJSON { response in
            
            guard let dict = response.value as? Dictionary<String, Any> else {return completion(nil)}
            guard let body = dict["body"] as? Dictionary<String, Any> else {return completion(nil)}
            guard let sessionData = body["sessionData"] as? [String: Any] else {return completion(nil)}
            let session = Session(data: sessionData)
            completion(session)
        }
    }
    
    func acceptRequest(parameters: [String:Any], completion: @escaping(Bool) -> Void) {
        let url = "https://us-central1-cueboom-46a61.cloudfunctions.net/acceptRequest"
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: [:]).responseJSON { response in
        
            guard let dict = response.value as? Dictionary<String, Any> else {return completion(false)}
            guard let status = dict["status"] as? Int else {return completion(false)}
            print("SHAHIN: status: \(status)")
            if status == 0 {
                completion(false)
            } else if status == 1 {
                completion(true)
            }
        }
    }
    
    func playRequest(parameters: [String:Any], completion: @escaping(Bool) -> Void) {
        let url = "https://us-central1-cueboom-46a61.cloudfunctions.net/playRequest"
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: [:]).responseJSON { response in
            
            guard let dict = response.value as? Dictionary<String, Any> else {return completion(false)}
            
            guard let status = dict["status"] as? Int else {return completion(false)}
            
            print("SHAHIN: status: \(status)")
            
            if status == 0 {
                completion(false)
            } else if status == 1 {
                completion(true)
            } else {
                print("ERROR...SHOULD NOT RUN THIS BLOCK")
            }
            
        }
    }
    
    func createCharge(vc: UIViewController, token: String, amount: Double, djStripeID: String, completion: @escaping(String) -> Void)  {
        print("SHAHIN: amount: \(amount)")
        let parameters: [String:Any] = ["token": token, "amount": amount, "djConnectID": djStripeID]
        let url = "https://us-central1-cueboom-46a61.cloudfunctions.net/createCharge"
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: [:]).responseJSON { response in
            
            guard let dict = response.value as? [String: Any]? else {
                print("Could not parse properly dict")
                return completion("")
            }
            
            guard let dict2 = dict?["body"] as? [String: Any] else {
                print("Could not parse properly dict2")
                return
            }
            
            guard let dict3 = dict2["Success"] as? String else {
                guard let errMessage = dict2["Failure"] as? String else {
                    print("Could not parse properly")
                    return
                }
                
                Alerts.errMessage(view: vc, message: errMessage)
                return
            }
            
            completion(dict3 as! String)
        }
    }
    
    ///For DJ to have the ability to be payed out
    func createStripeConnectAccount(uid: String, completion: @escaping(String?, String?) -> Void)  { //accountID, Error
        
        let parameters: [String:Any] = [:]
        
        let url = "https://us-central1-cueboom-46a61.cloudfunctions.net/createConnectAccount"
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: [:]).responseJSON { response in
            
            guard let dict = response.value as? [String: Any]? else {
                return completion(nil, "Error Creating Stripe Connect Account")
            }
        
            let dict2 = dict!["body"] as! [String: Any]
            let dict3 = dict2["success"] as! String
            
            print(dict3)
            let db = Firestore.firestore()
            db.collection("djs_private").document(uid).updateData(["connectID": dict3 as! String]) { (err) in
                if err != nil {
                    print(err)
                    return
                }
                completion(dict3, nil)
            }
        }
    }

    func createAccountLink(accountID: String, completion: @escaping(String?, String?) -> Void)  { //url, err
        
        let parameters: [String:Any] = ["accountID": accountID]
        
        let url = "https://us-central1-cueboom-46a61.cloudfunctions.net/createStripeAccountLink"
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: [:])
            .responseJSON { response in
            
            guard let dict = response.value as? [String: Any]? else {
                return completion(nil, "Error possibly...")
            }

            let dict2 = dict!["body"] as! [String: Any]
            let dict3 = dict2["success"] as! String
            
            print(dict3)
            completion(dict3, nil)
        }
    }
    
    func addBankAccount(accountID: String, routingNumber: String, accountNumber: String, bankName: String, vc: UIViewController, completion: @escaping(String?) -> Void)  {
        
        let parameters: [String:Any] = ["accountID": accountID, "routingNumber": routingNumber, "accountNumber": accountNumber, bankName: bankName]
        let url = "https://us-central1-cueboom-46a61.cloudfunctions.net/addBankAccount"
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: [:]).responseJSON { response in
            
            guard let dict = response.value as? [String: Any]? else {
                Alerts.errMessage(view: vc, message: "Error getting bank accounts: \(response)")
                return completion(nil)
            }
            
            let dict2 = dict!["body"] as! [String: Any]
            
            guard let dict3 = dict2["success"] as? String else {
                if let failure = dict2["failure"] as? String {
                    Alerts.errMessage(view: vc, message: "Error adding bank account: \(failure)")
                    return completion(nil)
                }
                
                return
            }
            
            print(dict3)
            completion(dict3)
        }
    }
    
    func getBankAccounts(accountID: String, vc: UIViewController, completion: @escaping([[String: Any]]?) -> Void)  {
        
        let parameters: [String:Any] = ["accountID": accountID]
        let url = "https://us-central1-cueboom-46a61.cloudfunctions.net/getBankAccounts"
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: [:]).responseJSON { response in
            
            guard let dict = response.value as? [String: Any]? else {
                Alerts.errMessage(view: vc, message: "Error getting bank accounts: \(response)")
                return completion(nil)
            }
            
            let dict2 = dict!["body"] as! [String: Any]
            
            guard let dict3 = dict2["success"] as? [[String: Any]] else {
                if let failure = dict2["failure"] as? String {
                    Alerts.errMessage(view: vc, message: "Error getting bank accounts: \(failure)")
                    return completion(nil)
                }
                
                return
            }
            
            print(dict3)
            completion(dict3)
        }
    }
    
    func deleteBankAccount(accountID: String, bank: String, vc: UIViewController, completion: @escaping(Bool) -> Void)  {
        
        let parameters: [String:Any] = ["accountID": accountID, "bank": bank]
        let url = "https://us-central1-cueboom-46a61.cloudfunctions.net/deleteBankAccount"
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: [:]).responseJSON { response in
            
            guard let dict = response.value as? [String: Any]? else {
                Alerts.errMessage(view: vc, message: "Error getting bank accounts: \(response)")
                return completion(false)
            }
            
            let dict2 = dict!["body"] as! [String: Any]
            
            guard let dict3 = dict2["success"] as? Bool else {
                if let failure = dict2["failure"] as? String {
                    Alerts.errMessage(view: vc, message: "Error deleting bank accounts: \(failure)")
                    return completion(false)
                }
                
                return
            }
            
            print(dict3)
            completion(dict3)
        }
    }
    
    func makeDefaultBankAccount(accountID: String, bank: String, vc: UIViewController, completion: @escaping(String?) -> Void)  {
        
        let parameters: [String:Any] = ["accountID": accountID, "bank": bank]
        let url = "https://us-central1-cueboom-46a61.cloudfunctions.net/updateDefaultBank"
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: [:]).responseJSON { response in
            
            guard let dict = response.value as? [String: Any]? else {
                Alerts.errMessage(view: vc, message: "Error getting bank accounts: \(response)")
                return completion(nil)
            }
            
            let dict2 = dict!["body"] as! [String: Any]
            
            guard let dict3 = dict2["success"] as? String else {
                if let failure = dict2["failure"] as? String {
                    Alerts.errMessage(view: vc, message: "Error deleting bank accounts: \(failure)")
                    return completion(nil)
                }
                
                return
            }
            
            print(dict3)
            completion(dict3)
        }
    }
    
    
    func initiatePayoutACH(accountID: String, bank: String, vc: UIViewController, completion: @escaping(String?) -> Void)  {
        
        let parameters: [String:Any] = ["bank": bank, "accountID": accountID]
        let url = "https://us-central1-cueboom-46a61.cloudfunctions.net/initiatePayout"
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: [:]).responseJSON { response in
            
            guard let dict = response.value as? [String: Any]? else {
                Alerts.errMessage(view: vc, message: "Error getting bank account information: \(response)")
                return completion(nil)
            }
            
            let dict2 = dict!["body"] as! [String: Any]
            
            guard let dict3 = dict2["success"] as? String else {
                if let failure = dict2["failure"] as? String {
                    Alerts.errMessage(view: vc, message: "Error initiating payout: \(failure)")
                    return completion(nil)
                }
                
                return completion(nil)
            }
            
            print(dict3)
            completion(dict3)
        }
    }
    
    func getStripeAvailableBalance(connectAccountID: String, vc: UIViewController, completion: @escaping(String?, String?, Int?) -> Void)  {
        
        let parameters: [String:Any] = ["stripeID": connectAccountID]
        let url = "https://us-central1-cueboom-46a61.cloudfunctions.net/getUserBalance"
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: [:]).responseJSON { response in
            
            guard let dict = response.value as? [String: Any]? else {
                Alerts.errMessage(view: vc, message: "Error getting bank account information: \(response)")
                return completion(nil, nil, nil)
            }
            
            let dict2 = dict!["body"] as! [String: Any]
            
            guard let dict3 = dict2["success"] as? [String : Any] else {
                if let failure = dict2["failure"] as? String {
                    Alerts.errMessage(view: vc, message: "Error getting balance: \(failure)")
                    return completion(nil, nil, nil)
                }
                return
            }
    
            print(String(describing: dict2["success"]))
            guard let availableObject = dict3["available"] as? [[String: Any]] else {
                return
            }
            
            guard let pendingObject = dict3["pending"] as? [[String: Any]] else {
                return
            }
            
            let available_amount = availableObject[0]["amount"] as! Int
            let pending_amount = pendingObject[0]["amount"] as! Int
            
            let formattedAvailable = Utilities.formatCurrency(amount: (Double(available_amount)/100))
            let formattedPending = Utilities.formatCurrency(amount: (Double(pending_amount)/100))
            completion(formattedAvailable, formattedPending, available_amount)
        }
    }
    
    func getTransferCapability(connectAccountID: String, vc: UIViewController, completion: @escaping(Bool?) -> Void)  { //If true, they are good, if false, stop and send to stripe stuff
        
        let parameters: [String:Any] = ["accountID": connectAccountID]
        let url = "https://us-central1-cueboom-46a61.cloudfunctions.net/checkTransferCapability"
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: [:])
            .responseJSON { response in
                guard let dict = response.value as? [String: Any]? else {
                    Alerts.errMessage(view: vc, message: "Error getting bank account information: \(response)")
                    return completion(nil)
                }
                
                guard let dict2 = dict?["body"] as? [String: Any] else {
                    Alerts.errMessage(view: vc, message: "Error getting balance.")
                    return completion(nil)
                }
                
                guard let _ = dict2["success"] as? String? else {
                    if let failure = dict2["failure"] as? String {
                        Alerts.errMessage(view: vc, message: "Error getting balance: \(failure)")
                        return completion(nil)
                    }
                    return
                }
        
                print(String(describing: dict2["success"]))
                
                if dict2["success"] as? String == "inactive" {
                    completion(false)
                } else {
                    completion(true)
                }
            }
    }
    
    func createTipCharge(djUID: String, token: String, amount: Double, djStripeID: String, completion: @escaping(String) -> Void)  {
        print("SHAHIN: amount: \(amount)")
        let parameters: [String:Any] = ["sessionID": userService.shared.currentSession!.sessionUid, "djUID": djUID, "token": token, "amount": amount, "djConnectID": djStripeID]
        let url = "https://us-central1-cueboom-46a61.cloudfunctions.net/createTipCharge"
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: [:])
            .validate()
            .responseJSON { response in
            
            guard let dict = response.value as? [String: Any]? else {
                return completion("")
            }
            
            //guard let status = dict?["Success"] as? String else {
            //  return completion("")
            //}
            
            let dict2 = dict!["body"] as! [String: Any]
            let dict3 = dict2["success"]
            print(dict3 as! String)
            completion(dict3 as! String)
        }
    }
    
    func welcomeEmail(email: String, name: String, completion: @escaping(Bool) -> Void) {
        //
        
        let parameters: [String:Any] = ["email": email, "name": name]
        let url = "https://europe-west2-football-hub-dev-de9cc.cloudfunctions.net/api/welcomeEmail"
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: [:])
            .validate()
            .responseJSON { response in
            
            guard let dict = response.value as? [String: Any]? else {
                return completion(false)
            }
            
            guard let status = dict?["status"] as? Bool else {
              return completion(false)
            }

            completion(status)
        }
    }
    
    
}
