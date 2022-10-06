//
//  userTransactionHistoryViewController.swift
//  cueBoom
//
//  Created by Charles Oxendine on 5/23/20.
//  Copyright © 2020 CueBoom LLC. All rights reserved.
//

import UIKit
import FirebaseFirestore

class userTransactionHistoryViewController: UIViewController {

    @IBOutlet weak var history_table: UITableView!
    
    var transactionData = [QueryDocumentSnapshot]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.history_table.delegate = self
        self.history_table.dataSource = self
        
        getData()
        setUI()
    }
    
    func setUI() {
        self.history_table.layer.cornerRadius = 20
    }
    
    func getData() {
        let db = Firestore.firestore()
        var uid = userService.shared.uid
        db.collection("transactions").whereField("userUid", isEqualTo: userService.shared.uid).getDocuments { (snap, err) in
            if err != nil {
                Alerts.shared.okWithCompletionHandler(viewController: self, title: "Error getting transaction data.", message: err!.localizedDescription) {
                    return
                }
            }
                self.transactionData = snap!.documents
                self.history_table.reloadData()
        }
    }
}


extension userTransactionHistoryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.transactionData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "transaction")
        let current_transaction = self.transactionData[indexPath.row].data()
        
        guard let amount = current_transaction["amount"] as? Int else {
            Alerts.shared.okWithCompletionHandler(viewController: self, title: "Error getting transaction data.", message: "Check your internet connection and try again. If the problem persists please contact customer support.") {
                self.dismiss(animated: true, completion: nil)
            }
            return cell!
        }
        
        cell?.textLabel?.text = "DJ: \(current_transaction["dJName"] as! String)"
        
        if current_transaction["tip"] as? Bool == true {
            cell?.detailTextLabel?.text = "Tipped \(Utilities.formatCurrency(amount: Double(amount)))"
        } else {
            cell?.detailTextLabel?.text = "\(Utilities.formatCurrency(amount: Double(amount)))"
        }
        return cell!
    }
}
