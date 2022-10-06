//
//  FindDJVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/30/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import FirebaseFirestore

class FindDJVC: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var sessions = [Session]()

    private var _venueName: String!
    var venueName: String {
        get {
            return _venueName
        } set {
            _venueName = newValue
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        if _venueName != nil {
            let query = FirestoreService.shared.REF_SESSIONS.whereField("venueName", isEqualTo: _venueName).whereField("ended", isEqualTo: false)
            query.getDocuments { (snapshot, error) in
                guard error == nil else {return}
                guard let docs = snapshot?.documents else {return}
                for doc in docs {
                    let id = doc.documentID
                    FirestoreService.shared.getSessionData(sessionUid: id, completion: { sessionData in
                        guard var sessionData = sessionData else {return}
                        
                        let session = Session(data: sessionData)
                        let currentDate = Date()
                        
                        if session.endTime.dateValue() > session.startTime.dateValue().addingTimeInterval(TimeInterval(-43200)) && session.ended == false {
                            self.sessions.append(session)
                            self.tableView.reloadData()
                        }
                    })
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.customMakeOpaque()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.customMakeTranslucent()
    }
    
    @IBAction func unwindToFindDJFromConfirmInfo(_ segue: UIStoryboardSegue) {}
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? UserConfirmInfoVC {
            if let session = sender as? Session {
                dest.session = session
            }
        }
    }
}

extension FindDJVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 181
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "DjCell") as? DjCell {
            cell.configureCell(session: sessions[indexPath.row])
            return cell
        } else {
            return DjCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "toConfirm", sender: sessions[indexPath.row])
    }
}
