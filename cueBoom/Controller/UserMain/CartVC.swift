//
//  CartVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 6/13/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import PassKit
import Stripe
import SwiftKeychainWrapper

class CartVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noCartItemsLbl: UILabel!
    @IBOutlet weak var checkOutButton: RoundedButton!
    
    var djConnectID: String?
    var transactionID = ""
    var paymentRequest = PKPaymentRequest()
    //Cart items are simply queue items owned by the user that have been accepted by the DJ and are ready for payment
    var cartItems = [QueueItem]()
    var amountDue: Double {
        get {
            var amt:Double = 0
            _ = cartItems.map({ amt += $0.price })
            return amt
        }
    }
    
    private var _currentSession: Session!
    var currentSession: Session {
        get {
            return _currentSession
        } set {
            _currentSession = newValue
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        getDJConnectID()
    
        self.checkOutButton.isEnabled = false
        activityIndicator.startAnimating() //Start loading
        
        //Fetch cart items
        if _currentSession != nil {
            fetchCartItems() {
                self.activityIndicator.stopAnimating() //Stop animating
                if self.cartItems.isEmpty { //No cart items. Handle view
                    self.updateViewForEmptyCart()
                } else {
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
        
        //Left bar button
        let exitBtn = UIBarButtonItem(image: UIImage(named: "exit"), style: .plain, target: self, action: #selector(exit))
        exitBtn.tintColor = UIColor.white
        navItem.setLeftBarButton(exitBtn, animated: true)
    }
    
    func getDJConnectID() {
        Firestore.firestore().collection("djs_private").document(self.currentSession.djUid).getDocument { (snap, err) in
            if err != nil {
                Alerts.errMessage(view: self, message: "Couldn't get dj connect ID")
                return
            }
            
            guard snap?.data() != nil else {
                Alerts.errMessage(view: self, message: "It seems that this DJ has deleted their account. Please close the app and refresh, our support team has been notified.")
                return
            }
            
            print(self.currentSession.djUid)
            self.djConnectID = snap?.data()!["connectID"] as! String
            self.checkOutButton.isEnabled = true
        }
    }
    
    //IBAction
    @IBAction func checkoutBtnTapped(_ sender: Any) {
        guard !cartItems.isEmpty else {return}
        
        //Check that Apple pay is enabled and device supports Apple Pay
        if !StripeAPI.deviceSupportsApplePay() {
//            Alerts.shared.ok(viewController: self, title: "Apple Pay", message: "This device doesn't support Apple pay")
            Alerts.shared.ok(viewController: self, title: "Enable Apple Pay", message: "Allow Apple Pay to checkout.")
            return
        }
        
        let paymentNetwork: [PKPaymentNetwork] = [.amex, .discover, .masterCard, .visa]//, .discover
        guard PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: paymentNetwork) else {
            return Alerts.shared.ok(viewController: self, title: "Enable Apple Pay", message: "Allow Apple Pay to checkout.")
        }

        let merchantID = "merchant.com.quincyjones.cueBoom"
        let paymentRequest = StripeAPI.paymentRequest(withMerchantIdentifier: merchantID, country: "US", currency: "USD")

        // Configure the line items on the payment request
        paymentRequest.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Song Requests", amount: NSDecimalNumber(value: amountDue)),
            PKPaymentSummaryItem(label: "cueBoom", amount: NSDecimalNumber(value: amountDue)),
        ]

        if !StripeAPI.canSubmitPaymentRequest(paymentRequest) {
            Alerts.shared.ok(viewController: self, title: "Apple Pay", message: "Something went wrong, please try later.")
            return
        }
        
        guard let paymentAuthorizationVC = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) else {
            //Handle error
            Alerts.shared.ok(viewController: self, title: "Payment", message: "Something went wrong, please try later.")
            return
        }

        paymentAuthorizationVC.delegate = self
        present(paymentAuthorizationVC, animated: true)
    }
    
    func itemsToSell() -> [PKPaymentSummaryItem] {
        let item = PKPaymentSummaryItem(label: "Song requests", amount: NSDecimalNumber(value: amountDue))
        
        return [item]
    }
    
    func fetchCartItems(completion: @escaping() -> Void) {
        let uid = userService.shared.uid
        FirestoreService.shared.REF_SESSIONS.document(_currentSession.sessionUid).collection("queue").whereField("userUid", isEqualTo: uid).whereField("queueStatus", isEqualTo: QueueStatus.accepted.rawValue).getDocuments { (snapshot, error) in
            guard let docs = snapshot?.documents else {return}
            for doc in docs {
                let queueItem = QueueItem(id: doc.documentID, data: doc.data())
                self.cartItems.append(queueItem)
            }
            //All cart items loaded
            completion()
        }
    }
    
    func updateViewForEmptyCart() {
        tableView.isHidden = true
        noCartItemsLbl.text = "Cart items will appear here when the DJ accepts your request."
    }
    
    @objc func exit() {
        self.dismiss(animated: true, completion: nil)
    }

}

extension CartVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 76
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cartItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CartItemCell") as? CartItemCell else {return CartItemCell()}
        
        let queueItem = cartItems[indexPath.row]
        cell.configureCell(queueItem: queueItem)
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, path) in
            self.activityIndicator.startAnimating()
            let cartItemToDelete: QueueItem = self.cartItems[path.row]
            self.cartItems.remove(at: path.row)
            
            //Delete from firestore
            FirestoreService.shared.REF_SESSIONS.document(self._currentSession.sessionUid).collection("queue").document(cartItemToDelete.id).delete(completion: { (error) in
                self.activityIndicator.stopAnimating()
                guard error == nil else {
                    return Alerts.shared.ok(viewController: self, title: "Something went wrong", message: "Please try again.")
                }
            })
     
            //Remove from table view
            tableView.deleteRows(at: [path], with: .fade)
        }
        
        return [delete]
    }
    
    func addTransactionToDB(completion: @escaping() -> Void) {
        //add transaction object to db
        guard _currentSession != nil else {
            completion()
            return
        }
        
        let uid = userService.shared.uid
        let group = DispatchGroup()
        group.enter(); group.enter()
        
        var songIDs: [String] = []
        for song in self.cartItems {
            songIDs.append(song.id)
        }
        
        let data: [String:Any] = ["dJName" : self.currentSession.djName, "amount": self.amountDue , "djUid" : self.currentSession.djUid, "sessionUid" : self.currentSession.sessionUid, "timestamp": Date(), "userUid" : uid, "venueAddress" : self.currentSession.venueAddress, "venueName" : self.currentSession.venueName, "transactionID" : self.transactionID, "songs" : songIDs, "tip": false]
        
        FirestoreService.shared.addTransaction(data: data) { (success) in
            group.leave()
        }
        
        FirestoreService.shared.batchSetCartItemsReadyToPlay(cartItems: cartItems, sessionId: _currentSession.sessionUid) { succes in
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.cartItems.removeAll()
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            completion()
        }
    }
}

extension CartVC: PKPaymentAuthorizationViewControllerDelegate {
    
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {
        
        //Create stripe token
        STPAPIClient.shared.createToken(with: payment) { (token: STPToken?, error: Error?) in
            guard let token = token, error == nil else {
                print("SHAHIN: error: \(error?.localizedDescription)")
                completion(.failure)
                return Alerts.shared.ok(viewController: self, title: "Something went wrong", message: "Payment failed. Please try again.")
            }
            
            CloudFunctions.shared.createCharge(vc: self, token: token.tokenId, amount: self.amountDue, djStripeID: self.djConnectID!, completion: { (success) in
                if success == nil {
                    completion(.failure)
                    return Alerts.shared.ok(viewController: self, title: "Something went wrong", message: "Payment failed. Please try again.")
                }
                
                self.transactionID = success
                
                self.addTransactionToDB {
                    completion(.success)
                    //change num to "ready to play" or 4
                }
            })
        }
    }
    
    //TRIGGERING FAILURE HERE SOMEWHERE???
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true, completion: nil)
        self.dismiss(animated: true, completion: nil)
    }
}

extension CartVC: STPAddCardViewControllerDelegate, STPApplePayContextDelegate {//STPApplePayContextDelegate
    func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: STPPaymentMethod, paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock) {
        print(paymentInformation)
    }
    
    func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPPaymentStatus, error: Error?) {
        print(status)
    }
    
    func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController) {
            print("Payment canceled")
            addCardViewController.dismiss(animated: true, completion: nil)
        }

        func addCardViewController(_ addCardViewController: STPAddCardViewController, didCreateToken token: STPToken, completion: (Error?) -> Void) {
            print("Card token: \(token.tokenId)")
        }
        
        func addCardViewController(_ addCardViewController: STPAddCardViewController, didCreatePaymentMethod paymentMethod: STPPaymentMethod, completion: @escaping STPErrorBlock) {
            print("")
        }
}
