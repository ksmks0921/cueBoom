//
//  UserRequestVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/19/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import FirebaseFirestore
import GeoFire
class UserRequestVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segCtrl: UISegmentedControl!
    @IBOutlet weak var songSearchBtnView: UIView!
    @IBOutlet weak var mapBtnView: UIView!

    
    //var indicator: IndicatorLineView!
    
    var totalRequests = [Request]()
    var searchedRequests = [Request]()
    
    var totalActiveSessions = [Session]()
    var searchedSessions = [Session]()
    
    var searchBarView: SearchBarView!
    var locationManager = CLLocationManager()

    override func viewDidLoad() {
        
        //Table view delegate/data source set in IB
        //Search bar delegate set in IB
        
        locationManager.delegate = self
        
        searchBarView = Bundle.main.loadNibNamed("SearchBarView", owner: self, options: nil)?.first as! SearchBarView
        searchBarView.searchBar.delegate = self
        
        //Set song search button and bg hidden
        songSearchBtnView.isHidden = true
        
        
        let profileBtn = UIBarButtonItem(image: UIImage(named: "profile"), style: .plain, target: self, action: #selector(toProfile))
        let searchBtn = UIBarButtonItem(image: UIImage(named: "search"), style: .plain, target: self, action: #selector(displaySearchBar))
        
        profileBtn.tintColor = UIColor.white
        searchBtn.tintColor = UIColor.white
        self.navigationItem.setLeftBarButton(profileBtn, animated: true)
        self.navigationItem.setRightBarButton(searchBtn, animated: true)
        
        //TODO: If nothing exists, pre-populate with default data
        //Load recent requests in decending order by timestamp
        let requestsQuery = FirestoreService.shared.REF_REQUESTS.order(by: "timestamp", descending: true)
        FirestoreService.shared.REF_REQUESTS.getDocuments { (snapshot, error) in
            guard error == nil, let docs = snapshot?.documents else {return}
            print("got docs, docs count is \(snapshot?.documents.count)")
            for doc in docs {
                let data = doc.data()
                let request = Request(requestData: data)
                self.totalRequests.append(request)
                self.searchedRequests = self.totalRequests
              //  self.tableView.reloadData()
                
            }
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {
        locationAuthStatus()
    }

    @IBAction func segCtrlTapped(_ sender: Any) {
        print("requests count is \(searchedRequests.count)")
        //Recents
        if segCtrl.selectedSegmentIndex == 1 {
            tableView.reloadData()
            //Handle bottom buttons
            songSearchBtnView.isHidden = false
            mapBtnView.isHidden = true
        //Nearby djs
        } else {
            //Handle bottom buttons
            songSearchBtnView.isHidden = true
            mapBtnView.isHidden = false
            //Only sort if location services are enabled. Otherwise, distanceFromUser property is nil
            if locationManager.location != nil {
                //totalActiveSessions.sort(by: {$0.distanceFromUser < $1.distanceFromUser})
                //searchedSessions.sort(by: {$0.distanceFromUser < $1.distanceFromUser})
                
            } else {
              
                Alerts.shared.ok(viewController: self, title: "Almost there!", message: "Finding nearby DJs depends on your location. Please enable location access in Settings.")
            }
            tableView.reloadData()
        }
       
        //animateIndicatorLine()
    }
    

    //Navigation item right/left btn actions
    @objc func toProfile() {
        performSegue(withIdentifier: "toProfile", sender: nil)
    }
    
    //Animation display of search bar
    @objc func displaySearchBar() {
        //Check that search bar isn't already in subview
        guard !view.subviews.contains(searchBarView) else {return}
        
        //Display keyboard
        searchBarView.searchBar.becomeFirstResponder()
        
        //Animate bar down
        searchBarView.frame = CGRect(x: 0, y: -56, width: self.view.frame.width, height: 56)
        view.addSubview(searchBarView)
        
        UIView.animate(withDuration: 0.4) {
            self.searchBarView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 56)
        }
    }
    
    func getActiveVenues() {
        guard let currentLoc = locationManager.location else {return}
        var keys = [String]()
        let geoFire = GeoFire(firebaseRef: RealtimeService.shared.REF_ACTIVE_VENUES)
        var query: GFCircleQuery?
        query = geoFire.query(at: currentLoc, withRadius: 3000)
        
        //The key that enters is the sessionUid of the session stored in Firestore
        query?.observe(.keyEntered, with: { (key: String!, location: CLLocation!) in
            //Add key to keys array
            keys.append(key)
        })
        
        query?.observeReady({
            self.getSessionData(keys: keys) {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
          
            }
        })
        
    }
    
    func getSessionData(keys: [String], completion: @escaping()-> Void) {
        var counter = 0
        print(keys.count)
        for key in keys {
            FirestoreService.shared.getSessionData(sessionUid: key) { data in
                guard var data = data else {return}
                
                let session = Session(data: data, userLoc: self.locationManager.location)
                self.totalActiveSessions.append(session)
               // self.totalActiveSessions.sort(by: {$0.distanceFromUser < $1.distanceFromUser})
                self.searchedSessions = self.totalActiveSessions
                counter += 1
                print(counter )
                //TODO: make this dispatch work group
                if counter == keys.count {
                    completion()
                }
            }
        }
        
    }
    
    
    
    
//    func animateIndicatorLine() {
//        let seg0CenterX = segCtrl.frame.width * 0.25
//        let seg1CenterX = segCtrl.frame.width * 0.75
//
//        if segCtrl.selectedSegmentIndex == 0 { //Animate to the left
//            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
//                self.indicatorLine.center.x = seg0CenterX
//            }, completion: nil)
//        } else if segCtrl.selectedSegmentIndex == 1 { //Animate to the right
//            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
//                self.indicatorLine.center.x = seg1CenterX
//            }, completion: nil)
//        }
//
//    }

}

extension UserRequestVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segCtrl.selectedSegmentIndex == 1 {
            return searchedRequests.count
        } else {
            return searchedSessions.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("Index path is \(indexPath.row)")
        if segCtrl.selectedSegmentIndex == 1 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "RequestCell") as? RequestCell {
                cell.configureRequestCell(request: searchedRequests[indexPath.row])
                return cell
            } else {
                return RequestCell()
            }
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "RequestCell") as? RequestCell {
                cell.configureDjCell(session: searchedSessions[indexPath.row])
                return cell
            } else {
                return RequestCell()
            }
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 191.5
        
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected")
        
        if segCtrl.selectedSegmentIndex == 0 {
            
          
        } else {
            
           
            
        }
        //Alerts.shared.ok(viewController: self, title: "Request", message: "A")
        //TODO:
        //Request, payment flow
    }

}

extension UserRequestVC: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    //Filter the totalRequests into displayedRequests based on search text and reload tablew view data
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard searchText != "" else {
            searchedRequests = totalRequests
            searchedSessions = totalActiveSessions
            tableView.reloadData()
            return
        }
        
        //Lower case the search text
        let text = searchText.lowercased()
        
        //String.contains is case sensitive. Lowercase both search text and filtered fields for case-insensitive filter
        if segCtrl.selectedSegmentIndex == 1 {
            searchedRequests = totalRequests.filter({$0.artistName.lowercased().contains(text) || $0.songName.lowercased().contains(text)})
            tableView.reloadData()
        } else {
            searchedSessions = totalActiveSessions.filter({$0.djName.lowercased().contains(text) || $0.venueName.lowercased().contains(text)})
            tableView.reloadData()
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
        removeSearchBar()
    }
    
    func removeSearchBar() {
        UIView.animate(withDuration: 0.4, animations: {
            self.searchBarView.frame = CGRect(x: 0, y: -56, width: self.view.frame.width, height: 56)
        }) { (true) in
            self.searchBarView.removeFromSuperview()
        }
    }
    
}

extension UserRequestVC: CLLocationManagerDelegate {
    // Shows location if it's been authorized; if not, ask for permission
    func locationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
            getActiveVenues()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        }
    }
}
