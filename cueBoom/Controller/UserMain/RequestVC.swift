//
//  RequestVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 6/7/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import Alamofire
import SwiftKeychainWrapper
import FirebaseFirestore
import FirebaseAuth
//import FirebaseFirestore

// RequestVC:
// Display queue items for the current session
// Users can search for songs to request to the DJ
// Default to displaying queue items. When user enters text in search bar, table view will switch to display songs from Apple Music api. Therefore, tableViewArray will take on elements of type QueueItem or of type Song.


class RequestVC: UIViewController {
    
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var sessionInfoViewContainer: UIView!
    @IBOutlet weak var queueStatusLbl: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tipButton: UIButton!
    @IBOutlet weak var homeButton: UIButton!
    
    var sessionInfoView: SessionInfoView!
    var searchBar: CustomSearchBar!
    var isSearchBarDispalyed: Bool = false
    var musicSearch = MusicSearch()
    var tableViewArray = [Any]()
    var queueItems = [QueueItem]()
    
    var queueListener: ListenerRegistration!
    var cartListener: ListenerRegistration!
    
    var currentSession: Session? = userService.shared.currentSession ?? nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //if self.currentSession == nil {
            self.tipButton.isHidden = true
            activityIndicator.startAnimating() //Start loading
            fetchQueue()
        //}
        
        //Set music search delegate
        musicSearch.delegate = self
        
        //Add left bar button
        let searchBtn = UIBarButtonItem(image: UIImage(named: "search"), style: .plain, target: self, action: #selector(animateSearchBar))
        searchBtn.tintColor = UIColor.white
        self.navItem.setLeftBarButton(searchBtn, animated: true)
        
        //Initialize sessionInfoView and add to view
        let container = sessionInfoViewContainer.bounds
        let containerRect = CGRect(x: container.minX, y: container.minY, width: UIScreen.main.bounds.width, height: 65)
        sessionInfoView = SessionInfoView(frame: containerRect)
        sessionInfoViewContainer.addSubview(sessionInfoView)
        sessionInfoViewContainer.bringSubviewToFront(sessionInfoView)
        initSessionViewModel()
        
        //Initialize search bar
        searchBar = CustomSearchBar(frame: CGRect(x: 0, y: -1000, width: view.frame.width, height: 56))
        searchBar.placeholder = "Search for any song..."
        searchBar.delegate = self
//        view.addSubview(searchBar)

        self.tipButton.layer.cornerRadius = self.tipButton.frame.height/2
        self.tipButton.layer.shadowColor = UIColor.black.cgColor
        self.tipButton.layer.shadowOpacity = 0.8
        self.tipButton.layer.shadowOffset = .zero
        self.tipButton.layer.shadowRadius = 3
        
        self.homeButton.layer.cornerRadius = self.homeButton.frame.height/2
        self.homeButton.layer.shadowColor = UIColor.black.cgColor
        self.homeButton.layer.shadowOpacity = 0.8
        self.homeButton.layer.shadowOffset = .zero
        self.homeButton.layer.shadowRadius = 3
    
        // CLOSING SEARCH VIEWS
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        restoreQueueUI()
        UIView.animate(withDuration: 0.4, animations: {
            self.searchBar.frame.origin = CGPoint(x: 0, y: -56)
            self.tableViewTopConstraint.constant = 0
        })
        isSearchBarDispalyed = false
    }
    
    // Get all queue items for the current session
    func fetchQueue() {
        CloudFunctions.shared.getCurrentSession { (session) in
            self.activityIndicator.stopAnimating()
            let defaults = UserDefaults.standard
            
            if let session = session {
                self.currentSession = session
                self.sessionInfoView.updateUI(forSession: self.currentSession ?? Session(), shouldDisplayCartInfo: true)
                self.setQueueListener()
                self.setCartItemsListener()
            } else if userService.shared.currentSession != nil {
                self.currentSession = userService.shared.currentSession ?? Session()
                self.sessionInfoView.updateUI(forSession: self.currentSession ?? Session(), shouldDisplayCartInfo: true)
                self.setQueueListener()
                self.setCartItemsListener()
            } else if defaults.string(forKey: "session") as? String != nil {
                FirestoreService.shared.getSessionData(sessionUid: defaults.string(forKey: "session") as! String) { (sessionRaw) in
                    guard session != nil else { return }
                    let currentSession = Session(data: sessionRaw ?? ["":""])
                    userService.shared.currentSession = currentSession
                    self.currentSession = userService.shared.currentSession ?? Session()
                    self.sessionInfoView.updateUI(forSession: currentSession ?? Session(), shouldDisplayCartInfo: true)
                    self.setQueueListener()
                    self.setCartItemsListener()
                }
            } else {
                //UI for no session
                self.setViewForNoQueue(labelText: "Select a venue below to get started.")
                let storyboard = UIStoryboard(name: "UserMain", bundle: nil)
                if let vc = storyboard.instantiateViewController(withIdentifier: "UserMainSelectVenueVC") as? UserMainSelectVenueVC {
                    if self.currentSession != nil { //Pass the current session if it exists
                        vc.currentSession = self.currentSession!
                    }
                    
                    self.present(vc, animated: true, completion: nil) //Present venue selection vc
                }
            }
        }
    }
    
    //view for no queue
    func setViewForNoQueue(labelText: String) {
        queueStatusLbl.text = labelText
        queueStatusLbl.isHidden = false
    }
    
    //View for when queue exists
    func setViewForQueue() {
        queueStatusLbl.isHidden = true
    }
    
    // Segue to => load the sessions
    // Unwind to => clear and load only if the current session is different => need to clear listeners as well
    //
    
    @IBAction func unwindToRequestVC(segue: UIStoryboardSegue) {
        //Update session info view UI elements
        if currentSession != nil {
            sessionInfoView.updateUI(forSession: currentSession ?? Session(), shouldDisplayCartInfo: true) //Update ui
            queueItems.removeAll() //Empty the queue items
            tableViewArray.removeAll()
            tableView.reloadData()
            setQueueListener() //Set queue listener for this session
            setCartItemsListener() //Set cart items listener for this session
        }
    }
    
    @IBAction func homeButton(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func tipButtonTapped(_ sender: Any) {
        guard self.currentSession != nil else {
            return
        }
        
        let storyboard = UIStoryboard(name: "UserMain", bundle: nil)
        let newVC = storyboard.instantiateViewController(withIdentifier: "tipCheckOut")
        self.present(newVC, animated: true)
    }
    
    @IBAction func unwindFromBidVCToRequestVC(segue: UIStoryboardSegue) {}
    
    //Set listener for new queue items
    func setQueueListener() {
        guard currentSession != nil else { return }
        
        guard currentSession!.sessionUid != "" else { return }
        
        self.tipButton.isHidden = false
        
        //Remove any previous listeners
        if queueListener != nil {
            queueListener.remove()
        }
        
        activityIndicator.startAnimating() //Start loading animation
        queueListener = FirestoreService.shared.REF_SESSIONS.document(currentSession!.sessionUid).collection("queue").whereField("userUid", isEqualTo: userService.shared.uid).order(by: "timestamp").addSnapshotListener { (snapshot, error) in self.activityIndicator.stopAnimating()
            
            guard let documentChanges = snapshot?.documentChanges else {return}
            for change in documentChanges {
                //TODO: handle remove case
                if change.type == .added {
                    let data = change.document.data()
            
                    let queueItem = QueueItem(id: change.document.documentID, data: data)
                    //Check if a song request already exists in the queue. If so, access that queueItem, increment it's number of requests, reload table view. Don't add the new request to the array
                    for i in 0..<self.queueItems.count {
                        if self.queueItems[i].songTitle == queueItem.songTitle && self.queueItems[i].artistName == queueItem.artistName { //Song request already exists
                            queueItem.incrementNumRequests(prevCount: self.queueItems[i].numRequests)
                            self.queueItems.remove(at: i)
                            break
                        }
                    }
                    //Add queueItem to front of the array, to make descending by timestamp
                    self.queueItems.insert(queueItem, at: 0)
                }
                
                if change.type == .removed {
                    self.queueItems = self.queueItems.filter({$0.id != change.document.documentID})
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
            
            //Queue items all loaded
            //UI if no queue items
            if self.queueItems.isEmpty {
                self.setViewForNoQueue(labelText: "No songs in the queue yet. Make a song request to start the queue!")
            //Queue items exist
            } else {
                self.tableView.isHidden = false
                self.tableViewArray = self.queueItems
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    //Get number of total cart items for the user for the current session
    func setCartItemsListener() {
        guard currentSession != nil else {return}
        let uid = userService.shared.uid
        //Remove any previous listeners
        if cartListener != nil {
            cartListener.remove()
        }
        cartListener = FirestoreService.shared.REF_SESSIONS.document(currentSession!.sessionUid).collection("queue").whereField("userUid", isEqualTo: uid).addSnapshotListener { (snapshot, error) in
            guard let documents = snapshot?.documents else {return}
            var numCartItems = 0
            for doc in documents {
                let queueItem = QueueItem(id: doc.documentID, data: doc.data())
                if queueItem.queueStatus == .accepted {
                    numCartItems += 1
                }
            }
            
            self.sessionInfoView.numCartItemsLbl.text = String(numCartItems)
        }
    }
    
    //Because the projected was rushed, had no time to restructure VC's such that BicVC handles the logic of posting songs requests. The quick and dirtiest solution was to pass the entire closure to BidVC.
    func getSongClosure(_ song: Song) -> ((Double, @escaping() -> Void) -> Void) {
        let closure: ((Double, @escaping() -> Void) -> Void) = { bid, completion in
            guard self.currentSession != nil else {return}
            
            let refQueue = Firestore.firestore().collection("sessions").document(self.currentSession?.sessionUid ?? "").collection("queue")
            refQueue.whereField("songTitle", isEqualTo: song.songTitle)
                .whereField("artistName", isEqualTo: song.artistName).getDocuments { (snap, err) in
                if err != nil {return}
                
                if snap?.documents != nil {
                    for doc in snap!.documents {
                        if doc.data()["queueStatus"] as! Int == 4 {
                            let deleteRef = refQueue.document(doc.data()["queueItemUID"] as! String)
                            deleteRef.delete()
                        }
                    }
                }
            }
            
            let queueItemUID = UUID().uuidString
            let data: [String: Any] = [
                "songTitle"     : song.songTitle,
                "artistName"    : song.artistName,
                "albumArtUrl"   : song.albumArtUrl,
                "albumName"     : song.albumName,
                "userUid"       : userService.shared.uid,
                "djUid"         : self.currentSession!.djUid,
                "price"         : bid,
                "timestamp"     : Date(),
                "queueStatus"   : QueueStatus.pending.rawValue,
                "queueItemUID"  : queueItemUID
            ]
            
            FirestoreService.shared.REF_SESSIONS.document(self.currentSession!.sessionUid).collection("queue").document(queueItemUID).setData(data) { (error) in
                guard error == nil else {
                    print(Auth.auth().currentUser!.uid)
                    print(error!.localizedDescription)
                    return Alerts.shared.okWithCompletionHandler(viewController: self, title: "Something went wrong", message: "Please try your request again.") {
                        completion()
                    }
                }
                
                Alerts.shared.okWithCompletionHandler(viewController: self, title: "Success", message: "Request placed successfully. You will be notified when the DJ accepts the request.") {
                    completion()
                }
            }
        }
        
        return closure
    }

     //SHAHIN: Because the projected was rushed, had no time to restructure VC's such that BicVC handles the logic of posting songs requests. The quick and dirtiest solution was to pass the entire closure to BidVC.
    func getQueueItemClosure(queueItem: QueueItem) -> ((Double, @escaping() -> Void) -> Void) {
        
        let refQueue = Firestore.firestore()
            .collection("sessions").document(self.currentSession!.sessionUid)
            .collection("queue")
            
        refQueue.whereField("songTitle", isEqualTo: queueItem.songTitle)
            .whereField("artistName", isEqualTo: queueItem.artistName)
            .getDocuments { (snap, err) in
            if err != nil {return}
            if snap?.documents != nil {
                for doc in snap!.documents {
                    if doc.data()["queueStatus"] as! Int == 4 {
                        let deleteRef = refQueue.document(doc.data()["queueItemUID"] as! String)
                        deleteRef.delete()
                    }
                }
            }
        }
        
        let closure: (Double, @escaping() -> Void) -> Void = { bid, completion in
            guard self.currentSession != nil else {return} //TODO: handle error
            let queueItemUid = UUID().uuidString
            let data: [String: Any] = [
                "songTitle"     : queueItem.songTitle,
                "artistName"    : queueItem.artistName,
                "albumArtUrl"   : queueItem.albumArtUrl,
                "albumName"     : queueItem.albumName,
                "userUid"       : userService.shared.uid,
                "djUid"         : self.currentSession!.djUid,
                "price"         : bid,
                "timestamp"     : Date(),
                "queueStatus"   : QueueStatus.pending.rawValue,
                "queueItemUID"  : queueItemUid
            ]
            
            FirestoreService.shared.REF_SESSIONS.document(self.currentSession!.sessionUid).collection("queue").document(queueItemUid).setData(data) { (error) in
                guard error == nil else {
                    return Alerts.shared.okWithCompletionHandler(viewController: self, title: "Something went wrong", message: "Please try your request again.") {
                        completion()
                    }
                }
                Alerts.shared.okWithCompletionHandler(viewController: self, title: "Success", message: "Request placed successfully. You will be notified when the DJ accepts the request.") {
                    completion()
                }
            
            }
        }
        
        return closure
    }
    
    @objc func menuBtnTapped() {
        //NAV TO MENU
        let storyboard = UIStoryboard(name: "UserMain", bundle: nil)
        let newVC = storyboard.instantiateViewController(withIdentifier: "UserMenuVC") as! UserMenuVC
        self.navigationController?.pushViewController(newVC, animated: true)
    }
    
    //Animate search bar down. Animate top constraint of table view to allow space for search bar above table view
    @objc func animateSearchBar() {
        guard currentSession != nil else {
            Alerts.shared.ok(viewController: self, title: "Select a venue", message: "Choose your venue below before searching for songs")
            return
        }
        
        if isSearchBarDispalyed == true {
            searchBar.removeFromSuperview()
            //TODO: this is patchwork code to hide table view when a queue exists but no queue items. In this case, when user hides search bar, if there are still no queue items, need to keep table view hidden.
            if queueItems.isEmpty == true {
                tableView.isHidden = true
            }
            searchBar.text = ""
            searchBar.resignFirstResponder()
            searchBar.showsCancelButton = false
            restoreQueueUI()
            UIView.animate(withDuration: 0.4, animations: {
                self.searchBar.frame.origin = CGPoint(x: 0, y: -56)
                self.tableViewTopConstraint.constant = 0
            })
            isSearchBarDispalyed = false
        } else if isSearchBarDispalyed == false {
            
            view.addSubview(searchBar)
            tableView.isHidden = false //TODO: this is patchwork view handling
            searchBar.becomeFirstResponder() //Show keyboard automatically
            UIView.animate(withDuration: 0.4, animations: {
                self.searchBar.frame.origin = CGPoint(x: 0, y: 0)
                self.tableViewTopConstraint.constant = self.searchBar.frame.height
            })
            isSearchBarDispalyed = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? CartVC, let currentSession = sender as? Session {
            dest.currentSession = currentSession
        }
        
        if let dest = segue.destination as? BidVC, let dataFromRequestVC = sender as? [Any] {
            dest.dataFromRequestVC = dataFromRequestVC
            self.view.endEditing(true)
            self.animateSearchBar()
        }
    }
}

extension RequestVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 192
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GenericSongCell") as? GenericSongCell else {
            return GenericSongCell()
        }
        
        if let queueItem = tableViewArray[indexPath.row] as? QueueItem {
            cell.configureCell(queueItem: queueItem)
        } else if let imgSongTuple = tableViewArray[indexPath.row] as? (UIImage, Song) {
            cell.configureCell(imgSongTuple: imgSongTuple)
        } else if let song = tableViewArray[indexPath.row] as? Song {
            cell.configureCell(song: song)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let element = tableViewArray[indexPath.row]
        
        if let queueItem = element as? QueueItem {
            //Confirm the request
            Alerts.shared.standardAlert(vc: self, title: "Confirm", message: "Place request to play \(queueItem.songTitle)?", negativeOption: "Cancel", affirmativeOption: "Continue") { didConfirm in
                //If user confirms, create the request from QueueItem struct
                if didConfirm == true {
                    FirestoreService.shared.checkForIdenticalRequest(songName: queueItem.songTitle, artistName: queueItem.artistName, sessionID: self.currentSession!.sessionUid) { (duplicate_status) in
                        if duplicate_status == nil {
                            print("no duplicate song requests")
                            self.performSegue(withIdentifier: "RequestToBid", sender: [self.getQueueItemClosure(queueItem: queueItem), queueItem]);
                            return
                        }
                        
                        Alerts.shared.ok(viewController: self, title: "You already requested this song!", message: "Psst...if you wanna give some more to a DJ, donate with the heart button in the bottom right corner!")
                        self.performSegue(withIdentifier: "RequestToBid", sender: [self.getQueueItemClosure(queueItem: queueItem), queueItem]);
                    }
                }
            }
        } else if let imgSongTuple = element as? (UIImage, Song) {
            //Confirm the request
            Alerts.shared.standardAlert(vc: self, title: "Confirm", message: "Place request to play \(imgSongTuple.1.songTitle)?", negativeOption: "Cancel", affirmativeOption: "Continue") { didConfirm in
                //If user confirms, create the request from Song struct
                if didConfirm {
                    self.performSegue(withIdentifier: "RequestToBid", sender: [self.getSongClosure(imgSongTuple.1), imgSongTuple.1])
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteItem = UITableViewRowAction(style: .destructive, title: "Delete") { (action, index) in
               self.activityIndicator.startAnimating()
               let itemToDelete: QueueItem = self.queueItems[index.row]
            self.queueItems.remove(at: index.row)
            self.tableViewArray.remove(at: index.row)
               
               //Delete from firestore
            FirestoreService.shared.REF_SESSIONS.document(self.currentSession!.sessionUid).collection("queue").document(itemToDelete.id).delete(completion: { (error) in
                   self.activityIndicator.stopAnimating()
                   guard error == nil else {
                       return Alerts.shared.ok(viewController: self, title: "Something went wrong", message: "Please try again.")
                   }
                   
               })
        
               //Remove from table view
               tableView.deleteRows(at: [index], with: .fade)
        }
        
        deleteItem.backgroundColor = .red
        
        return [deleteItem]
    }
    
}

extension RequestVC: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
        //Table view array is filled with queue items. Empty the array of queue items. Array will take on Song elements as user searches through song library.
        tableViewArray.removeAll()
        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard searchText.count > 2 else {
            tableViewArray.removeAll()
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            return
        }
        
        
        musicSearch.search(searchText: searchText)
        activityIndicator.startAnimating() //Start loading animation for music search
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        animateSearchBar()
        //During search, table view array has been accepting song elements. Now, set the array equal to queue items again, as user has ended search. Reload table view to display queue items
        restoreQueueUI()
        self.setQueueListener()
    }
    
    func restoreQueueUI() {
        tableViewArray = queueItems
        tableView.reloadData()
    }
}

extension RequestVC: MusicSearchDelegate {
    func didGetSearchResults(songs: [Song]?) {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating() //Stop loading anim. for music search
        }
        guard let songs = songs else {return}
        
        var data = [(UIImage, Song)]()
        // For each song, fetch image
        let group = DispatchGroup()
        
        for song in songs {
            group.enter()
            ImageService.shared.downloadAlbumArt(url: song.albumArtUrl) { (image) in
                DispatchQueue.main.async {
                    data.append((image, song))
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.tableViewArray = data
            self.tableView.reloadData()
        }
        
    }
}

//Session info view "View model"
extension RequestVC {
    func initSessionViewModel() {
        let storyboard = UIStoryboard(name: "UserMain", bundle: .main)
        sessionInfoView.handleCartTap = {() in
            if let vc = storyboard.instantiateViewController(withIdentifier: "CartVC") as? CartVC {
                if self.currentSession != nil { //Pass the current session ID if it exists
                    vc.currentSession = self.currentSession!
                }
            
                self.present(vc, animated: true, completion: nil) //Present cart vc
            }
        }
        
        sessionInfoView.handleViewTap = {() in
            if let vc = storyboard.instantiateViewController(withIdentifier: "UserMainSelectVenueVC") as? UserMainSelectVenueVC {
                if self.currentSession != nil { //Pass the current session if it exists
                    vc.currentSession = self.currentSession!
                }
                
                self.present(vc, animated: true, completion: nil) //Present venue selection vc
            }
        }
    }
}
