//
//  tipCheckoutViewController.swift
//  cueBoom
//
//  Created by Charles Oxendine on 5/22/20.
//  Copyright © 2020 CueBoom LLC. All rights reserved.
//

import UIKit
import Stripe
import FirebaseFirestore
import PassKit

class tipCheckoutViewController: UIViewController {

    @IBOutlet weak var oneDollarTipSelect: RoundedButton!
    @IBOutlet weak var twoDollarTipSelect: RoundedButton!
    @IBOutlet weak var fiveDollarTipSelect: RoundedButton!
    @IBOutlet weak var tenDollarTipSelect: RoundedButton!
    @IBOutlet weak var checkOutButton: RoundedButton!
    
    var djConnectID: String?
    var tipAmount: Double?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.checkOutButton.isEnabled = false
        getDJConnectID()
        setSelectedTipAmount(amount: 1)
    }

    func setSelectedTipAmount(amount: Int!) {
        switch amount {
            case 1:
                self.tipAmount = 1.00
                self.oneDollarTipSelect.backgroundColor = TEALISH
                self.twoDollarTipSelect.backgroundColor = .darkGray
                self.fiveDollarTipSelect.backgroundColor = .darkGray
                self.tenDollarTipSelect.backgroundColor = .darkGray
            case 2:
                self.tipAmount = 2.00
                self.oneDollarTipSelect.backgroundColor = .darkGray
                self.twoDollarTipSelect.backgroundColor = TEALISH
                self.fiveDollarTipSelect.backgroundColor = .darkGray
                self.tenDollarTipSelect.backgroundColor = .darkGray
            case 5:
                self.tipAmount = 5.00
                self.oneDollarTipSelect.backgroundColor = .darkGray
                self.twoDollarTipSelect.backgroundColor = .darkGray
                self.fiveDollarTipSelect.backgroundColor = TEALISH
                self.tenDollarTipSelect.backgroundColor = .darkGray
            case 10:
                self.tipAmount = 10.00
                self.oneDollarTipSelect.backgroundColor = .darkGray
                self.twoDollarTipSelect.backgroundColor = .darkGray
                self.fiveDollarTipSelect.backgroundColor = .darkGray
                self.tenDollarTipSelect.backgroundColor = TEALISH
            default:
                print("Something went wrong...")
        }
    }
    
    @IBAction func oneTipTapped(_ sender: Any) {
        setSelectedTipAmount(amount: 1)
    }
    
    @IBAction func twoTipTapped(_ sender: Any) {
        setSelectedTipAmount(amount: 2)
    }
    
    @IBAction func fiveTipTapped(_ sender: Any) {
        setSelectedTipAmount(amount: 5)
    }
    
    @IBAction func tenTipTapped(_ sender: Any) {
        setSelectedTipAmount(amount: 10)
    }
    
    @IBAction func checkoutTapped(_ sender: Any) {
        guard self.tipAmount != nil else {return}
        print(StripeAPI.deviceSupportsApplePay())
        
        //Check that Apple pay is enabled and device supports Apple Pay
        if StripeAPI.deviceSupportsApplePay() {
            Alerts.shared.ok(viewController: self, title: "Enable Apple Pay", message: "Allow Apple Pay to checkout.")
//            Alerts.shared.ok(viewController: self, title: "Apple Pay", message: "This device doesn't support Apple pay")
            return
        }
        
        let paymentNetwork: [PKPaymentNetwork] = [.amex, .discover, .masterCard, .visa]
        guard PKPaymentAuthorizationController.canMakePayments(usingNetworks: paymentNetwork) else {
            Alerts.shared.ok(viewController: self, title: "Enable Apple Pay", message: "Allow Apple Pay to checkout.")
            return
        }
        
        let merchantID = "merchant.com.quincyjones.cueBoom"
        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: merchantID, country: "US", currency: "USD")
        
        // Configure the line items on the payment request
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Song Requests", amount: NSDecimalNumber(value: tipAmount!)),
            PKPaymentSummaryItem(label: "cueBoom", amount: NSDecimalNumber(value: tipAmount!)),
        ]
        
        if !StripeAPI.canSubmitPaymentRequest(paymentRequest) {
            Alerts.shared.ok(viewController: self, title: "Apple Pay", message: "Something went wrong, please try later.")
            return
        }
        
        guard let paymentAuthorizationVC = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) else {
            //Handle error
            return
        }
        
        paymentAuthorizationVC.delegate = self
        present(paymentAuthorizationVC, animated: true)
    }
    
    func getDJConnectID() {
        let db = Firestore.firestore()
        db.collection("djs_private").document(userService.shared.currentSession!.djUid).getDocument { (snap, err) in
            if err != nil {
                Alerts.errMessage(view: self, message: "Couldn't get dj connect ID")
                return
            }
            
            guard snap?.data()?["connectID"] as? String != nil else {
                Alerts.errMessage(view: self, message: "This DJ Doesn't exist. This may be because they deleted their account. ")
                return
            }
            
            self.djConnectID = (snap?.data()!["connectID"] as! String)
            self.checkOutButton.isEnabled = true
        }
    }
}

extension tipCheckoutViewController: PKPaymentAuthorizationViewControllerDelegate {
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true, completion: nil)
        self.dismiss(animated: true, completion: nil)
    }
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {
        
        //Create stripe token
        STPAPIClient.shared.createToken(with: payment) {(token: STPToken?, error: Error?) in
            guard let token = token, error == nil else {
//                print("SHAHIN: error: \(error?.localizedDescription)")
                completion(.failure)
                return Alerts.shared.ok(viewController: self, title: "Something went wrong", message: "Payment failed. Please try again.")
            }
            
            CloudFunctions.shared.createTipCharge(djUID: userService.shared.currentSession!.djUid, token: token.tokenId, amount: self.tipAmount!, djStripeID: self.djConnectID!, completion: { (success) in
                if success == "" {
                    completion(.failure)
                    return Alerts.shared.ok(viewController: self, title: "Something went wrong", message: "Payment failed. Please try again.")
                }
                
                let data: [String:Any] = [
                    "dJName"        : userService.shared.currentSession!.djName,
                    "amount"        : self.tipAmount,
                    "djUid"         : userService.shared.currentSession!.djUid,
                    "sessionUid"    : userService.shared.currentSession?.sessionUid,
                    "timestamp"     : Date(),
                    "userUid"       : userService.shared.uid,
                    "venueAddress"  : userService.shared.currentSession!.venueAddress,
                    "venueName"     : userService.shared.currentSession!.venueName,
                    "transactionID" : success,
                    "songs"         : [],
                    "tip"           : true
                ]
                
                FirestoreService.shared.addTransaction(data: data) { (success) in
                    completion(.success)
                }
                
                //TO DO: CREATE TRANSACTION COLLECTION
            })
        }
    }
}
