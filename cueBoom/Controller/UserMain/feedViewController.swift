//
//  feedViewController.swift
//  cueBoom
//
//  Created by Charles Oxendine on 7/22/20.
//  Copyright © 2020 CueBoom LLC. All rights reserved.
//

import UIKit
import FirebaseFirestore

class feedViewController: UIViewController {

    @IBOutlet weak var onlineGigTable: UITableView!
    
    var sessionData: [Session] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        onlineGigTable.delegate = self
        onlineGigTable.dataSource = self
        
        getData()
    }
    
    func getData() {
        let db = Firestore.firestore()
        db.collection("sessions").whereField("onlineEvent", isEqualTo: true).whereField("startTime", isGreaterThan: Timestamp(date: Date())).whereField("ended", isEqualTo: false).getDocuments { (snap, err) in
            if err != nil {
                Alerts.errMessage(view: self, message: err!.localizedDescription)
                return
            }
            
            print(snap?.documents)
            guard snap?.documents.isEmpty != true else {
                print("empty")
                return
            }
            
            var sessionTableData: [Session] = []
            
            for documents in snap!.documents {
                let sessionData = documents.data()
                let sessionObject = Session(data: sessionData)
                
                sessionTableData.append(sessionObject)
            }
            
            self.sessionData = sessionTableData
            DispatchQueue.main.async {
                self.onlineGigTable.reloadData()
            }
        }
    }
}

extension feedViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sessionData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "feedCell") as? feedTableViewCell {
            let currentSession = self.sessionData[indexPath.row]
            cell.setCell(session: currentSession)
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var session = self.sessionData[indexPath.row]
        userService.shared.currentSession = session
        
        performSegue(withIdentifier: "toMain", sender: session)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


