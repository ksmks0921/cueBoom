//
//  DJGigsVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/8/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import Firebase

class DJGigsVC: UIViewController {
    @IBOutlet weak var segCtrl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView! //Table view delegate & data source set in IB
    @IBOutlet weak var indicatorLine: UIView!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var currentDate = Date()
    
    //A "gig" corresponds to the "Session" data model, i.e. upcoming gigs = upcoming sessions, past gigs = past sessions.
    var upcomingSessions = [Session]() {
        didSet {
            //Sort upcoming sessions in ascending order\
            upcomingSessions.sort(by: {$0.startTime.dateValue() < $1.startTime.dateValue()})
        }
    }
    
    var pastSessions = [Session]() {
        didSet {
            //Sort past sessions in descending order
            pastSessions.sort(by: {$0.startTime.dateValue() > $1.startTime.dateValue()})
        }
    }
    
    var mostRecentDocId: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Add DJ main menu to front of the navigation stack - if its not already there - so that on menu tap, we can pop instead of a left segue
        addMenuToStack()
        
        //Set sessions listener
        setSessionsListener()
        
        //Configure indicator line
        let indicatorY = segCtrl.frame.origin.y + segCtrl.frame.height
        indicatorLine.frame = CGRect(x: 0, y: indicatorY, width: view.frame.width/2, height: 4)
        
        //Create right bar item: "Add New"
        let addNewBarBtn = UIBarButtonItem(title: "Add New", style: .plain, target: self, action: #selector(addNewTapped))
        let attrs = [NSAttributedString.Key.font: UIFont(name: "Roboto-Light", size: 14) as Any,NSAttributedString.Key.foregroundColor: UIColor.white]
        addNewBarBtn.setTitleTextAttributes(attrs, for: .normal)
        addNewBarBtn.setTitleTextAttributes(attrs, for: .selected)
        //Add left bar button: menu
        let menuBtn = UIBarButtonItem(image: UIImage(named: "menu"), style: .plain, target: self, action: #selector(menuBtnTapped))
        menuBtn.tintColor = UIColor.white
        self.navItem.setLeftBarButton(menuBtn, animated: true)
        //Set right bar button to "Edit" initially
        navItem.rightBarButtonItem = addNewBarBtn
    }
    
    func addMenuToStack() {
        guard let vcs = navigationController?.viewControllers, let firstVC = vcs.first, !firstVC.isKind(of: DJMainMenuVC.self) else {return}
        let storyboard = UIStoryboard(name: "DJMain", bundle: .main)
        let mainMenuVC = storyboard.instantiateViewController(withIdentifier: "DJMainMenuVC") 
        navigationController?.viewControllers.insert(mainMenuVC, at: 0)
    }
    
    func setSessionsListener() {
        //Set listener to get all sessions in djs_public/{djUid}/sessions
        //TODO: reload table view on gig update, i.e. when documentChange is .modified
        activityIndicator.startAnimating() //Start loading anim.
        FirestoreService.shared.REF_CURRENT_DJ_SESSIONS
            .addSnapshotListener(includeMetadataChanges: true) { (snapshot, error) in //ERROR
                self.activityIndicator.stopAnimating() //Stop loading anim.
                guard error == nil else {
                    return
                    
                }
                
                guard let docChanges = snapshot?.documentChanges else {return}
                for change in docChanges {
                    let doc = change.document
                    
                    //Workaround for firebase issue where listener fires twice for one document change. Storing a reference to a changed doc's ID and comparing all other doc changes to it to prevent running code twice
                    guard doc.documentID != self.mostRecentDocId else {continue}
                    self.mostRecentDocId = doc.documentID
                    
                    let sessionUid = doc.documentID
                    
                    //In the case where a dj makes an edit, filter that session out of array before re-adding edited version, so as to prevent duplicate in table view
                    if self.upcomingSessions.contains(where: {$0.sessionUid == sessionUid}) {
                        self.upcomingSessions = self.upcomingSessions.filter({$0.sessionUid != sessionUid })
                    }
                    
                    FirestoreService.shared.getSessionData(sessionUid: sessionUid, completion: { data in
                        guard let data = data else {return}
                        
                        let session = Session(data: data)
                        //Separate upcoming sessions from past sessions by comparing end time of session to current time
                        if session.startTime.dateValue() > self.currentDate.addingTimeInterval(TimeInterval(-43200)) && session.ended == false {
                            print(session.startTime.dateValue().getCustomTimeString())
                            self.upcomingSessions.append(session)
                        } else {
                            print(session.startTime.dateValue().getCustomTimeString())
                            self.pastSessions.append(session)
                        }
                        self.tableView.reloadData()
                    })
                }
        }
    }
    
    @IBAction func segCtrlTapped(_ sender: UISegmentedControl) {
        //Animate the indicator line
        switch sender.selectedSegmentIndex {
        case 0:
            animateIndicatorLeft()
            tableView.allowsSelection = true
        case 1:
            animateIndicatorRight()
            tableView.allowsSelection = false
        
            
        default:
            print("selected index not 0 or 1")
        }
        
        //Reload the table view data
        tableView.reloadData()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? DJEditGigVC {
            guard let session = sender as? Session else {return}
            destination.session = session
        }
        
        if let destination = segue.destination as? DJQueueVC {
            guard let sessionId = sender as? String else {return}
            destination.currentSessionId = sessionId
        }
    }
    
}

extension DJGigsVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segCtrl.selectedSegmentIndex {
        case 0:
            return upcomingSessions.count
        case 1:
            return pastSessions.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var sessionArr: [Session]?
        switch segCtrl.selectedSegmentIndex {
        case 0:
            sessionArr = upcomingSessions
        case 1:
            sessionArr = pastSessions
        default:
            print("selected index not 0 or 1")
        }
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "DJGigCell") as? DJGigCell {
            if let sessions = sessionArr {
                cell.delegate = self
                cell.configureCell(session: sessions[indexPath.row])
                return cell
            }
        }
        
        return DJGigCell()
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard segCtrl.selectedSegmentIndex == 0 else {return}
        
        performSegue(withIdentifier: "toQueue", sender: upcomingSessions[indexPath.row].sessionUid)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        //guard segCtrl.selectedSegmentIndex == 0 else {return nil} //Only allow deletions on upcoming sessions, not past sessions
        
        var action = UITableViewRowAction()
        switch self.segCtrl.selectedSegmentIndex {
        case 0:
            action = UITableViewRowAction(style: .destructive, title: "End") { (action, path) in
                
                let sessionToEnd = self.upcomingSessions[indexPath.row]
                
                let alert = UIAlertController(title: "Are you sure?", message: "If you end this gig you will never be able to make any edits to profits, play new songs, or reopen the gig...", preferredStyle: .alert)
                
                let verify = UIAlertAction(title: "End Gig", style: .default) { (actions) in
                    let db = Firestore.firestore()
                    db.collection("sessions").document(sessionToEnd.sessionUid).updateData(["ended" : true]) { (err) in
                        if err != nil {
                            print("Error updating doc: \(err)")
                            return
                        }
                    
                        self.upcomingSessions.remove(at: indexPath.row)
                        self.pastSessions.append(sessionToEnd)
                        self.tableView.reloadData()
                    }
                }
                
                alert.addAction(verify)
                self.present(alert, animated: true)
            }
            
            break
        case 1:
            action = UITableViewRowAction(style: .destructive, title: "Delete", handler: { (action, path) in
                var sessionToDelete = self.pastSessions[indexPath.row]
                self.pastSessions.remove(at: indexPath.row)
                FirestoreService.shared.deleteSession(sessionUid: sessionToDelete.sessionUid)
                RealtimeService.shared.deleteSession(sessionUid: sessionToDelete.sessionUid)
                tableView.deleteRows(at: [indexPath], with: .fade)
                self.tableView.reloadData()
            })
            
            break
        default:
            return [UITableViewRowAction()]
        }
        
        return [action]
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 79
    }
}

extension DJGigsVC: GigCellDelegate {
    func editBtnTapped(session: Session) {
        performSegue(withIdentifier: "toEdit", sender: session)
    }
}

//Bar button selectors
extension DJGigsVC {
    
    @objc func addNewTapped() {
        performSegue(withIdentifier: "toFindVenue", sender: nil)
    }
    
    @objc func menuBtnTapped() {
        //Popping to menu, which was inserting into stack in viewDidLoad
        navigationController?.popViewController(animated: true)
    }
    
}

//Indicator line animations
extension DJGigsVC {
    func animateIndicatorRight() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.indicatorLine.frame.origin.x = self.view.frame.width/2
        }, completion: nil)
    }
    func animateIndicatorLeft() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.indicatorLine.frame.origin.x = 0
        }, completion: nil)
    }
}
