//
//  catDJViewController.swift
//  cueBoom
//
//  Created by Charles Oxendine on 9/8/20.
//  Copyright © 2020 Shahin Firouzbakht. All rights reserved.
//

import UIKit
import FirebaseFirestore

class catDJViewController: UIViewController {

    @IBOutlet weak var djsTable: UITableView!
    
    var currentCat: musicCategory!
    var djRaw: [DjProfile] = []
    var djTableData: [djProfileObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        djsTable.delegate = self
        djsTable.dataSource = self
        
        setData()
    }
    
    func setData() {
        let db = Firestore.firestore()
        db.collection("djs_public").whereField("musicCat", isEqualTo: self.currentCat.rawValue).getDocuments { (snap, err) in
            if err != nil {
                Alerts.shared.ok(viewController: self, title: "Error", message: err!.localizedDescription)
                return
            }
            
            guard snap != nil else { return }
            
            var DJs: [DjProfile] = []
            
            for docs in snap!.documents {
                let djObject = DjProfile(profileData: docs.data(), uid: docs.documentID)
                DJs.append(djObject)
            }
            
            self.djRaw = DJs
            self.getImages() 
        }
    }
    
    func getImages() {
        
        let group = DispatchGroup()
        var finalData: [djProfileObject] = []
        
        for dj in self.djRaw {
            group.enter()
            if dj.djImgUrl != nil && dj.djImgUrl != ""{
                StorageService.shared.download(url: dj.djImgUrl!) { image in
                    if let image = image {
                        let object = djProfileObject(djPic: image, djObject: dj)
                        finalData.append(object)
                        group.leave()
                    } else {
                        let defaultImage = UIImage(systemName: "person.circle")
                        let object = djProfileObject(djPic: defaultImage, djObject: dj)
                        finalData.append(object)
                        group.leave()
                    }
                }
            } else {
                let defaultImage = UIImage(systemName: "person.circle")
                let object = djProfileObject(djPic: defaultImage, djObject: dj)
                finalData.append(object)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.djTableData = finalData
            self.djsTable.reloadData()
        }
    }
    
}

extension catDJViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.djTableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "djCell") as! djPublicTableViewCell
        let currentDJ = self.djTableData[indexPath.row]
        
        cell.setCell(dj: currentDJ.djObject, profileImage: currentDJ.djPic)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentDJ = self.djTableData[indexPath.row]
        
        let storyboard = UIStoryboard(name: "UserMain", bundle: nil)
        let newVC = storyboard.instantiateViewController(withIdentifier: "DJprofile") as! djProfileUserSideViewController
        newVC.dj = currentDJ.djObject
        self.navigationController?.pushViewController(newVC, animated: true)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
