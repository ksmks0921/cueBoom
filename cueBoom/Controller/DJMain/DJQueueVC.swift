//
//  DJQueueVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/16/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import FirebaseAuth
import FirebaseFirestore

//Multi song request
//One song requested by multiple people
//View: same as on guest side. banner with number of requests
//Backend: increment earnings by number of that same request

class DJQueueVC: UIViewController {
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segCtrl: UISegmentedControl!
    @IBOutlet weak var earningsLbl: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noRequestsLbl: UILabel!
    
    var segCtrlIndicator: UIView!
    
    var djQueue = DJQueue()
    
//    var newRequests = [QueueItem]()
//    var acceptedRequests = [QueueItem]()
//    var readyRequests = [QueueItem]()
    
    var tableViewArray = [StackedQueueItem]()
    
    var queueListener: ListenerRegistration!
    
    private var _currentSessionId: String!
    var currentSessionId: String {
        get {
            return _currentSessionId
        } set {
            _currentSessionId = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set firestore listener for queue and earnings
        setQueueListener()
        setEarningsListener()
        
        //Configure seg ctrl indicator line. Default placement underneath segment index 0
        segCtrlIndicator = UIView(frame: CGRect(x: 0, y: segCtrl.frame.origin.y + segCtrl.frame.height, width: self.view.frame.width/3, height: 2))
        segCtrlIndicator.backgroundColor = TEALISH
        view.addSubview(segCtrlIndicator)
    
    }

    
    //IBActions
    
    @IBAction func segCtrlTapped(_ sender: UISegmentedControl) {
        slideSegCtrlIndicator(segmentIndex: segCtrl.selectedSegmentIndex)//Slide the seg ctrl indicator
        updateUI() //Update the ui
        setTableViewArray() //Set table view array based on seg control index
        if sender.selectedSegmentIndex == 0 {
            tableView.isUserInteractionEnabled = true
        }
        
        if sender.selectedSegmentIndex == 1 {
            tableView.isUserInteractionEnabled = false
        }
        if sender.selectedSegmentIndex == 2 {
            tableView.isUserInteractionEnabled = true
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func setTableViewArray() {
        if segCtrl.selectedSegmentIndex == 0 {
            tableViewArray = djQueue.stackedNewRequests
        }
        if segCtrl.selectedSegmentIndex == 1 {
            tableViewArray = djQueue.stackedAcceptedRequests
        }
        if segCtrl.selectedSegmentIndex == 2 {
            tableViewArray = djQueue.stackedReadyRequests
        }
    }
    
    func updateUI() {
        
        if segCtrl.selectedSegmentIndex == 0 {
            //if new requests array is empty, hide table view, add label
            if djQueue.stackedNewRequests.isEmpty {
                noRequestsLbl.text = "No requests yet"
                tableView.isHidden = true
            } else {
                tableView.isHidden = false
                noRequestsLbl.text = ""
            }
        }
        if segCtrl.selectedSegmentIndex == 1 {
            //if accepted requests array is empty, hide table view, add label
            if djQueue.stackedAcceptedRequests.isEmpty {
                noRequestsLbl.text = "Requests that you accept will show up here"
                tableView.isHidden = true
            } else {
                tableView.isHidden = false
                noRequestsLbl.text = ""
            }
        }
        if segCtrl.selectedSegmentIndex == 2 {
            //if ready requests array is empty, hide table view, add label
            if djQueue.stackedReadyRequests.isEmpty {
                noRequestsLbl.text = "Nothing here yet"
                tableView.isHidden = true
            } else {
                tableView.isHidden = false
                noRequestsLbl.text = ""
            }
        }
    }
    
    func slideSegCtrlIndicator(segmentIndex: Int) {
        var x: CGFloat!
        if segmentIndex == 0 {
            x = 0
        }
        if segmentIndex == 1 {
            x = view.frame.width/3
        }
        if segmentIndex == 2 {
            x = view.frame.width*(2/3)
        }
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.segCtrlIndicator.frame.origin.x = x
        }, completion: nil)
    }
    
//    func setEarningsListerner() {
//        guard _currentSessionId != nil else {return}
//        FirestoreService.shared.REF_CURRENT_DJ_PRIVATE.collection("earnings_by_session").document(_currentSessionId).addSnapshotListener { (snapshot, error) in
//            guard let data = snapshot?.data() else {return}
//            guard let earnings = data["earnings"] as? Double else {return}
//            self.earningsLbl.text = String(format: "$%.02f", earnings)
//        }
//    }
    
    func setQueueListener() {
        guard _currentSessionId != nil else {return}
        activityIndicator.startAnimating()
        
        queueListener = FirestoreService.shared.REF_SESSIONS.document(_currentSessionId).collection("queue").addSnapshotListener({ (snapshot, error) in
            
            guard let snapshot = snapshot else {return}
            snapshot.documentChanges.forEach({ (change) in
                let queueItem = QueueItem(id: change.document.documentID, data: change.document.data())
                
                switch change.type {
                case .added:
                    self.djQueue.ProcessNew(queueItem)
                    break
                case .modified:
                    self.djQueue.ProcessModified(queueItem)
                    break
                case .removed:
                    self.djQueue.ProcessRemoved(queueItem)
                    break
                }
            })
            
            
            self.activityIndicator.stopAnimating()
            self.setTableViewArray()
            self.updateUI()
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
    }
    
    fileprivate func setEarningsListener() {
        FirestoreService.shared.REF_SESSIONS.document(self._currentSessionId)
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    Alerts.shared.ok(viewController: self, title: "Earnings", message: "Having trouble tracking earnings. Give us a minute.")
                    return
                }
                guard let data = document.data() else {
                    return
                }
                
                guard let earnings = data["totalEarnings"] as? Double else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.earningsLbl.text = String(format: "$%.02f", earnings)
                }
        }
    }

    @IBAction func amountEarnedHelp(_ sender: Any) {
        let alert = UIAlertController(title: "Amount Earned", message: "This is the total amount earned after fees.", preferredStyle: .alert)
        let closeAction = UIAlertAction(title: "Close", style: .default, handler: nil)
        
        alert.addAction(closeAction)
        self.present(alert, animated: true)
    }
}

extension DJQueueVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 79
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DJQueueItemCell") as? DJQueueItemCell else {
            return DJQueueItemCell()
        }
    
        cell.configureCell(stackedQueueItem: tableViewArray[indexPath.row])
        return cell
        
    }
    
    //TODO: <iOS 11.0 version of leading and trailing swipe
    //Leading swipe to 1. accept a song on "new requests" tab and 2. confirm a played song on "ready to play" tab
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        var action: UIContextualAction?
        if segCtrl.selectedSegmentIndex == 0 {
            action = getAcceptSongAction(indexPath: indexPath) //MARK: Calls Get accept song
        } else if segCtrl.selectedSegmentIndex == 2 {
            action = getPlaySongAction(indexPath: indexPath)
        }
        
    
        if let action = action {
            action.image = UIImage(named: "checkMark")
            action.backgroundColor = .black
            return UISwipeActionsConfiguration(actions: [action])
        }
        
        return nil

    }
    
    //Traililng swipe to reject a song request
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard segCtrl.selectedSegmentIndex == 0 else {return nil} //Only allow for new requests tab
        
        
        let deleteAction = UIContextualAction(style: .normal, title:  "Delete", handler: { (ac:UIContextualAction, view:UIView, success:@escaping (Bool) -> Void) in
            Alerts.shared.standardAlert(vc: self, title: "Confirm", message: "Reject this request?", negativeOption: "Cancel", affirmativeOption: "Yes", completion: { (affirmed) in
                if affirmed {
                    self.activityIndicator.startAnimating()
                    
                    let stackToDelete = self.tableViewArray[indexPath.row]
                    
                    self.tableViewArray.remove(at: indexPath.row)
                    
                    //Reload the table view
                    DispatchQueue.main.async {
                        tableView.reloadData()
                    }
                    
                    //Delete the queue items
                    let group = DispatchGroup()
                    for queueItem in stackToDelete.allQueueItems {
                        group.enter()
                        FirestoreService.shared.REF_SESSIONS.document(self._currentSessionId).collection("queue").document(queueItem.id).delete(completion: { (error) in
                            self.activityIndicator.stopAnimating()
                            guard error == nil else {
                                group.leave()
                                return
                            }
                            group.leave()
                          
                        })
                    }
                    
                    group.notify(queue: .main) {
                        Alerts.shared.ok(viewController: self, title: "Rejected", message: "Request successfully rejected.")
                    }
                    
                    success(true)

                }
            })
        })
        deleteAction.image = UIImage(named: "trash")
        deleteAction.backgroundColor = .black

        return UISwipeActionsConfiguration(actions: [deleteAction])

    }
    
    //Contextual action for when DJ swipes to accept a song
    func getAcceptSongAction(indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title:  "Accept", handler: {(ac:UIContextualAction, view:UIView, success: @escaping(Bool) -> Void) in
            
            Alerts.shared.standardAlert(vc: self, title: "Confirm", message: "Accept this request?", negativeOption: "Cancel", affirmativeOption: "Yes", completion: { (affirmed) in
                if affirmed {
                    self.activityIndicator.startAnimating()
                    
                    let stackToAccept = self.tableViewArray[indexPath.row]
                    self.tableViewArray.remove(at: indexPath.row)
                    
                    //Reload the table view
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                    
                    //Delete the queue items
                    let group = DispatchGroup()
                    for queueItem in stackToAccept.allQueueItems {
                        group.enter()
                        
                        let parameters: [String:Any] = [
                            "sessionId"     : self._currentSessionId!,
                            "queueItemId"   : queueItem.id,
                            "djUid"         : queueItem.djUid,
                            "userUid"       : queueItem.userUid
                        ]
                        
                        CloudFunctions.shared.acceptRequest(parameters: parameters, completion: { (success) in
                            guard success == true else {
                                group.leave()
                                return
                            }
                            group.leave()
                        })
                    }
                    
                    group.notify(queue: .main) {
                        self.activityIndicator.stopAnimating()
                        Alerts.shared.ok(viewController: self, title: "Accepted", message: "Request successfully accepted.")
                    }
                    
                    success(true)
                }
            })
        })
    
        return action
    }
    
    
    //Contextual action for when DJ confirms that a song is played
    func getPlaySongAction(indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title:  "Accept", handler: { (ac:UIContextualAction, view:UIView, success:@escaping(Bool) -> Void) in
            
            if self.tableViewArray[indexPath.row].stackedQueueStatus == .played {
                Alerts.shared.ok(viewController: self, title: "", message: "Song has already been played!");
                success(true)
                return
            }
            
            Alerts.shared.standardAlert(vc: self, title: "Confirm", message: "Play this song?", negativeOption: "Cancel", affirmativeOption: "Yes", completion: { (affirmed) in
                if affirmed {
                    
                    self.activityIndicator.startAnimating()
                    
                    let stackToPlay = self.tableViewArray[indexPath.row]
                    
                    //Reload the table view
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                    
                    let group = DispatchGroup()
                    for queueItem in stackToPlay.allQueueItems {
                        group.enter()
                        
                        let parameters: [String:Any] = ["sessionId": self._currentSessionId,
                                                        "queueItemId": queueItem.id
                        ]
                        
                        CloudFunctions.shared.playRequest(parameters: parameters, completion: { (success) in
                            
                            guard success == true else {
                                Alerts.shared.ok(viewController: self, title: "Error", message: "Error playing song. Check you network connect and try again. If the problem persists, please contact our support.")
                                return
                            }
                            
                            group.leave()
                        })
                    }
                    
                    group.notify(queue: .main) {
                        print("notified")
                        self.activityIndicator.stopAnimating()
                        Alerts.shared.ok(viewController: self, title: "Confirmed", message: "Please play '\(stackToPlay.song.songTitle)' by \(stackToPlay.song.artistName)")
                    }
                    
                    success(true)

                }
            })
        })
        
        return action
    }
}
