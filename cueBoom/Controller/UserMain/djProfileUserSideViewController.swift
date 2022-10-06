//
//  djProfileUserSideViewController.swift
//  cueBoom
//
//  Created by Charles Oxendine on 7/30/20.
//  Copyright © 2020 CueBoom LLC. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage

class djProfileUserSideViewController: UIViewController {

    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var djNameLbl: UILabel!
    
    @IBOutlet weak var fbButton: UIButton!
    @IBOutlet weak var instaButton: UIButton!
    @IBOutlet weak var twitterButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    
    @IBOutlet weak var upcomingSessionsTable: UITableView!
    
    var upcomingSessionData: [Session] = []
    var dj: DjProfile!
    var djName: String?
    var liked: Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "User Profile"
        
        self.upcomingSessionsTable.delegate = self
        self.upcomingSessionsTable.dataSource = self
        
        checkIfLiked()
        getUpcomingSessions()
        setData()
        getImage()
        setUI()
    }
    
    func setUI() {
        self.userImage.layer.cornerRadius = self.userImage.frame.height/2
        self.upcomingSessionsTable.layer.borderWidth = 1
        self.upcomingSessionsTable.layer.borderColor = UIColor.white.cgColor
        self.upcomingSessionsTable.layer.cornerRadius = 15
    }
    
    func setData() {
        self.djName = self.dj!.name
        self.djNameLbl.text = self.djName
        
        if self.dj.facebookName == nil || self.dj.facebookName == "" {
            self.fbButton.isEnabled = false
        }
        
        if self.dj.instagramHandle == nil || self.dj.instagramHandle == "" {
            self.instaButton.isEnabled = false
        }
        
        if self.dj.twitterHandle == nil || self.dj.twitterHandle == "" {
            self.twitterButton.isEnabled = false
        }
    }
    
    func getUpcomingSessions() {
        guard self.dj.uid != nil else { return }
        let db = Firestore.firestore()
        
        db.collection("sessions").whereField("djUid", isEqualTo: self.dj.uid!).whereField("startTime", isGreaterThan: Timestamp(date: Date())).whereField("ended", isEqualTo: false).getDocuments { (snap, err) in
            if err != nil {
                Alerts.errMessage(view: self, message: err!.localizedDescription)
                return
            }
            
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
            
            self.upcomingSessionData = sessionTableData
            self.upcomingSessionsTable.reloadData()
        }
    }
    
    func checkIfLiked() {
        guard self.dj.uid != nil else { return }
        
        let db = Firestore.firestore()
        db.collection("users_private").document(userService.shared.uid).getDocument { (snap, err) in
            if err != nil {
                return
            }
            
            guard snap?.data()?["following"] as? [String] != nil else {
                return
            }
            
            guard let following = snap?.data()?["following"] as? [String] else { return }
            guard following.isEmpty != true else { return }
            
            let thisUser = following.filter { $0 == self.dj.uid }
            if thisUser.isEmpty == false {
                self.likeButton.setBackgroundImage(UIImage(systemName: "heart.fill"), for: .normal)
                self.liked = true
            } else {
                self.likeButton.setBackgroundImage(UIImage(systemName: "heart"), for: .normal)
                self.liked = false
            }
        }
    }
    
    private func getImage() {
        if self.dj.djImgUrl != nil && self.dj.djImgUrl != ""{
            StorageService.shared.download(url: self.dj.djImgUrl!) { image in
                if let image = image {
                    self.userImage.image = image
                }
            }
        }
    }
    
    @IBAction func twitterTapped(_ sender: Any) {
        guard self.dj != nil else { return }
        if let appURL = URL(string: "twitter://user?screen_name=\(self.dj.twitterHandle!)") {
            let application = UIApplication.shared
            
            if application.canOpenURL(appURL) {
                application.open(appURL)
            } else {
                let webURL = URL(string: "https://twitter.com/\(self.dj.twitterHandle!)")!
                application.open(webURL)
            }
        }
    }
    
    @IBAction func facebookTapped(_ sender: Any) {
        guard self.dj != nil else { return }
        if let appURL = URL(string: "fb://profile/\(self.dj.facebookName!)") {
            let application = UIApplication.shared
            
            if application.canOpenURL(appURL) {
                application.open(appURL)
            } else {
                let webURL = URL(string: "https://www.facebook.com/\(self.dj.facebookName!)")!
                application.open(webURL)
            }
        }
    }
    
    @IBAction func likeButtonTapped(_ sender: Any) {
        guard self.dj.uid != nil else { return }
        
        if self.liked != true {
            let db = Firestore.firestore()
            db.collection("users_private").document(userService.shared.uid).updateData(["following" : FieldValue.arrayUnion([self.dj.uid!])]) { (err) in
                if err != nil {
                    Alerts.errMessage(view: self, message: err!.localizedDescription)
                    return
                }
   
                self.likeButton.setBackgroundImage(UIImage(systemName: "heart.fill"), for: .normal)
                self.liked = true
            }
        } else {
            let db = Firestore.firestore()
            db.collection("users_private").document(userService.shared.uid).updateData(["following" : FieldValue.arrayRemove([self.dj.uid!])]) { (err) in
                if err != nil {
                    Alerts.errMessage(view: self, message: err!.localizedDescription)
                    return
                }
                
                self.likeButton.setBackgroundImage(UIImage(systemName: "heart"), for: .normal)
                self.liked = false
            }
        }
    }
    
    @IBAction func instagramTapped(_ sender: Any) {
        guard self.dj != nil else { return }
        
        if let appURL = URL(string: "instagram://user?username=\(self.dj.instagramHandle!)") {
            let application = UIApplication.shared
                        
            if application.canOpenURL(appURL) {
                application.open(appURL)
            } else {
                let webURL = URL(string: "https://instagram.com/\(self.dj.instagramHandle!)")!
                application.open(webURL)
            }
        }
    }
    
    func getFormattedTime(time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: time)
    }
}

extension djProfileUserSideViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.upcomingSessionData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sessionCell")
        let currentSession = self.upcomingSessionData[indexPath.row]
        cell?.textLabel?.text = currentSession.venueName
        cell?.detailTextLabel?.text = getFormattedTime(time: currentSession.startTime.dateValue())
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
}

