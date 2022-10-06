//
//  searchDJsViewController.swift
//  cueBoom
//
//  Created by Charles Oxendine on 9/6/20.
//  Copyright © 2020 CueBoom LLC. All rights reserved.
//

import UIKit
import FirebaseFirestore

class searchDJsViewController: UIViewController {

    @IBOutlet weak var catCollection: UICollectionView!
    @IBOutlet weak var searchResultsTable: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    private let cats: [musicCategory] = [.RB, .rock, .pop, .electronic, .country, .hiphop]
    private var images: [UIImage]!
    
    var filteredData: [djProfileObject] = []
    var djData: [djProfileObject] = []
    var djRaw: [DjProfile] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.images = Utilities.images 
        
        self.searchResultsTable.delegate = self
        self.searchResultsTable.dataSource = self
        
        self.searchBar.delegate = self
        
        self.catCollection.delegate = self
        self.catCollection.dataSource = self
        
        self.getDJs()
        self.catCollection.contentInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        registerForKeyboardNotifications()
    }
   
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        let keyboardFrame = notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
        adjustLayoutForKeyboard(targetHeight: keyboardFrame.size.height)
    }
    
    @objc func keyboardWillHide(notification: NSNotification){
        adjustLayoutForKeyboard(targetHeight: 0)
    }
    
    func adjustLayoutForKeyboard(targetHeight: CGFloat) {
        searchResultsTable.contentInset.bottom = targetHeight
    }
    
    func getDJs() {
        let db = Firestore.firestore()
        db.collection("djs_public").getDocuments { (snap, err) in
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
            if dj.djImgUrl != nil && dj.djImgUrl != "" {
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
            self.djData = finalData
            self.filteredData = finalData
            self.searchResultsTable.reloadData()
        }
    }
    
}

extension searchDJsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let collectionViewSize = collectionView.bounds
        let squareSize = (collectionViewSize.width/2 - 20)
        return CGSize(width: squareSize, height: squareSize)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.cats.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentCat = self.cats[indexPath.row]
        
        let storyboard = UIStoryboard(name: "UserMain", bundle: nil)
        let newVC = storyboard.instantiateViewController(withIdentifier: "djCat") as! catDJViewController
        newVC.currentCat = currentCat
        self.navigationController?.pushViewController(newVC, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "music_cat", for: indexPath) as! catCollectionViewCell
        cell.setCell(cat: self.cats[indexPath.row], img: self.images[indexPath.row])
        return cell
    }
    
}

extension searchDJsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "djCell") as! djPublicTableViewCell
        let currentDJ = self.filteredData[indexPath.row]
        
        cell.setCell(dj: currentDJ.djObject, profileImage: currentDJ.djPic)
        return cell

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentDJ = self.djData[indexPath.row]
        
        let storyboard = UIStoryboard(name: "UserMain", bundle: nil)
        let newVC = storyboard.instantiateViewController(withIdentifier: "DJprofile") as! djProfileUserSideViewController
        newVC.dj = currentDJ.djObject
        self.navigationController?.pushViewController(newVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension searchDJsViewController: UISearchBarDelegate {
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        for one in djData {
            if let name = one.djObject.name, name.lowercased().contains(searchBar.text!.lowercased()) {
                filteredData.append(one)
            }
            
            if let facebookName = one.djObject.facebookName, facebookName.lowercased().contains(searchBar.text!.lowercased()) {
                filteredData.append(one)
            }
        }
        
//        let newFilteredData = self.djData.filter { $0.djObject.name!.lowercased().contains(searchBar.text!.lowercased()) == true }
//        self.filteredData = newFilteredData
        self.searchResultsTable.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchResultsTable.alpha = 1
        self.getDJs()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        for one in djData {
            if let name = one.djObject.name, name.lowercased().contains(searchBar.text!.lowercased()) {
                filteredData.append(one)
            }
            
            if let facebookName = one.djObject.facebookName, facebookName.lowercased().contains(searchBar.text!.lowercased()) {
                filteredData.append(one)
            }
        }
        
//        let newFilteredData = self.djData.filter { $0.djObject.name!.lowercased().contains(searchBar.text!.lowercased()) == true }
//        self.filteredData = newFilteredData
        self.searchResultsTable.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.getDJs()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchResultsTable.alpha = 0
        self.view.endEditing(true)
    }
}

struct djProfileObject {
    
    var djPic: UIImage!
    var djObject: DjProfile!
    
}
