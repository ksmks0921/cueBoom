//
//  payoutMainViewController.swift
//  cueBoom
//
//  Created by Charles Oxendine on 5/14/20.
//  Copyright © 2020 CueBoom LLC. All rights reserved.
//

import UIKit
import Firebase

class payoutMainViewController: UIViewController {

    @IBOutlet weak var banksTableView: UITableView!
    @IBOutlet weak var initiatePaymentButton: UIButton!
    @IBOutlet weak var currentBalance: UILabel!
    @IBOutlet weak var addCardButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var selectedBankLabel: UILabel!
    @IBOutlet weak var pendingBalanceLabel: UILabel!
    
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var coverViewLoading: UIActivityIndicatorView!
    
    private var banks = [[String : Any]]()
    private var selectedBank: [String : Any]?
    private var availableAmount: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.banksTableView.delegate = self
        self.banksTableView.dataSource = self
        
        setUI()
        getUserBalance()
        getBanks()
    }

    func setUI() {
        self.banksTableView.layer.cornerRadius = 15
        self.banksTableView.layer.borderColor = UIColor.darkGray.cgColor
        self.banksTableView.layer.borderWidth = 1
    }
    
    func getUserBalance() {
        CloudFunctions.shared.getStripeAvailableBalance(connectAccountID: userService.shared.connectID, vc: self) { (availableBalance, pendingBalance, availableInt) in
            self.currentBalance.text = availableBalance
            self.pendingBalanceLabel.text = pendingBalance
            self.availableAmount = availableInt
        }
    }
    
    func getBanks() {
        self.banksTableView.isUserInteractionEnabled = false
        self.initiatePaymentButton.isEnabled = false
        self.loadingIndicator.startAnimating()
        
        print(userService.shared.connectID)
        
        CloudFunctions.shared.getBankAccounts(accountID: userService.shared.connectID, vc: self) { (banks) in
            if banks == nil {
                print("some error getting banks...")
                return
            }
            
            self.banks = banks!
            self.banksTableView.reloadData()
            self.banksTableView.isUserInteractionEnabled = true
            self.initiatePaymentButton.isEnabled = true
            self.loadingIndicator.stopAnimating()
        }
    }
    
    @IBAction func addCardButtonTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "DJMain", bundle: nil)
        let newVC = storyboard.instantiateViewController(withIdentifier: "payoutRequest") as! payoutViewController
        newVC.delegate = self
        self.navigationController?.pushViewController(newVC, animated: true)
    }
    
    @IBAction func initiatePayoutTapped(_ sender: Any) {
        if self.availableAmount! < 500 {
            let alert = UIAlertController(title: "Oops!", message: "You have to have at least $5.00 to payout!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
            self.present(alert, animated: true)
        } else {
            self.coverView.alpha = 1
            self.coverViewLoading.startAnimating()
            let bankID = self.selectedBank!["id"] as! String
            CloudFunctions.shared.initiatePayoutACH(accountID: userService.shared.connectID, bank: bankID, vc: self) { (estimatedArrival) in
                self.getUserBalance()
                self.coverView.alpha = 0
                let alert = UIAlertController(title: "Payout sent!", message: "You can expect to see this credit on your account in the next 3-5 days.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }
    
    @IBAction func pendingHelpTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Pending Balance", message: "Pending balance are funds that are not yet available, due to the 7-day rolling pay cycle.", preferredStyle: .alert)
        let closeAction = UIAlertAction(title: "Close", style: .default, handler: nil)
        
        alert.addAction(closeAction)
        self.present(alert, animated: true)
    }
}

extension payoutMainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.banks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bankTableCell")
        let currentBank = self.banks[indexPath.row]
        
        var bankName = currentBank["bank_name"] as! String
        var last4 = currentBank["last4"] as! String
        
        cell?.textLabel?.text = "\(bankName) \(last4)"
        
        var defaultAccount = currentBank["default_for_currency"] as! Bool
        if defaultAccount == true {
            cell?.detailTextLabel!.text = "DEFAULT"
            self.selectedBank = currentBank
            self.selectedBankLabel.text = "Selected: \(bankName) \(last4)"
        } else {
            cell?.detailTextLabel!.text = ""
        }
        
        return cell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentBank = self.banks[indexPath.row]
        var bankName = currentBank["bank_name"] as! String
        var last4 = currentBank["last4"] as! String
        
        self.selectedBank = currentBank
        self.selectedBankLabel.text = "Selected: \(bankName) \(last4)"
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteTitle = NSLocalizedString("Delete", comment: "Delete action")
        let deleteAction = UITableViewRowAction(style: .destructive,
          title: deleteTitle) { (action, indexPath) in
            var currentBank = self.banks[indexPath.row]
            var currentDefault = currentBank["default_for_currency"] as! Bool
            
            if currentDefault == true {
                Alerts.errMessage(view: self, message: "You cannot delete your default card!")
            } else {
                let alert = UIAlertController(title: "Are you sure?", message: "Are you sure you want to delete this bank account? This action cannot be undone.", preferredStyle: .alert)
                let confirm = UIAlertAction(title: "Yes", style: .default) { (action) in
                    self.loadingIndicator.startAnimating()
                    CloudFunctions.shared.deleteBankAccount(accountID: userService.shared.connectID, bank: currentBank["id"] as! String, vc: self) { (confirmed) in
                        if confirmed == true {
                            self.banks.remove(at: indexPath.row)
                            self.banksTableView.reloadData()
                            
                            self.getBanks()
                            
                            let alert = UIAlertController(title: "Card Deleted", message: nil, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
                            self.present(alert, animated: true)
                        }
                    }
                }
                
                alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
                alert.addAction(confirm)
                self.present(alert, animated: true)
            }
        }
        
        let makeDefaultAction = UITableViewRowAction(style: .default, title: "Make Default") { (action, indexPath) in
            var currentBank = self.banks[indexPath.row]
            var currentDefault = currentBank["default_for_currency"] as! Bool
            
            if currentDefault == true {
                Alerts.errMessage(view: self, message: "That bank is already your default!")
            } else {
                let alert = UIAlertController(title: "Are you sure?", message: "Are you sure you want to change your default bank?", preferredStyle: .alert)
                let confirm = UIAlertAction(title: "Yes", style: .default) { (action) in
                    self.loadingIndicator.startAnimating()
                    CloudFunctions.shared.makeDefaultBankAccount(accountID: userService.shared.connectID, bank: currentBank["id"] as! String, vc: self) { (id) in
                        if id == nil {
                            print("something went wrong...")
                            return
                        }
                        
                        self.getBanks()
                        print(id)
                    }
                }
                
                alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
                alert.addAction(confirm)
                self.present(alert, animated: true)
            }
        }
        
        makeDefaultAction.backgroundColor = .green
        return [deleteAction, makeDefaultAction]
    }
}

extension payoutMainViewController: payoutViewControllerDelegate {
    func backTapped() {
        self.getBanks()
        self.getUserBalance()
        self.setUI()
    }
}
