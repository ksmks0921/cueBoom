//
//  dashBoardViewController.swift
//  cueBoom
//
//  Created by Charles Oxendine on 7/30/20.
//  Copyright © 2020 CueBoom LLC. All rights reserved.
//

import UIKit
import FirebaseAuth
import MapKit
import CoreLocation

class dashBoardViewController: UIViewController {

    @IBOutlet weak var recentDJCollection: UICollectionView!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var noRecentsLabel: UILabel!
    @IBOutlet weak var upcomingTable: UITableView!
    
    @IBOutlet weak var currentSessionView: UIView!
    @IBOutlet weak var djNameLbl: UILabel!
    @IBOutlet weak var sessionMapView: MKMapView!
    @IBOutlet weak var onlineEventCover: UIView!
    @IBOutlet weak var openCurrentSessionButton: UIButton!
    @IBOutlet weak var currentSessionLbl: UILabel!
    
    @IBOutlet weak var notifsView: UIView!
    @IBOutlet weak var notifsCount: UILabel!
    
    var djData:  [DjProfile] = []
    var sessionData: [Session] = []
    var newUser: Bool? = false
    
    let images = [
        UIImage(named: "cat-RB")!,
        UIImage(named: "cat-rock")!,
        UIImage(named: "cat-pop")!,
        UIImage(named: "cat-electronic")!,
        UIImage(named: "cat-country")!,
        UIImage(named: "cat-hiphop")!
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recentDJCollection.dataSource = self
        recentDJCollection.delegate = self
        
        upcomingTable.delegate = self
        upcomingTable.dataSource = self
        
        checkForAgreements()
        
        //Add right bar button
        setUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.setSessionMenu()
        self.setUI()
    }
    
    @objc func toRequest() {
        performSegue(withIdentifier: "toMain", sender: nil)
    }
    
    @objc func toSearch() {
        performSegue(withIdentifier: "toSearch", sender: self)
    }
    
    func setUI() {
        self.upcomingTable.layer.cornerRadius = 10
        
        self.notifsView.layer.cornerRadius = notifsView.frame.height/2
        
        self.currentSessionView.layer.cornerRadius = 15
        self.currentSessionView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    
        self.openCurrentSessionButton.layer.cornerRadius = 15
        self.openCurrentSessionButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        self.sessionMapView.layer.cornerRadius = 15
        self.onlineEventCover.layer.cornerRadius = 15
        
        setSessionMenu()
        
        if userService.shared.currentSession != nil {
            FirestoreService.shared.getAwaitingPaymentSessionsCount { (amount) in
                self.notifsCount.text = String(amount)
                self.notifsView.isHidden = false
            }
        } else {
            self.notifsView.isHidden = true
        }
    }
    
    func checkForAgreements() {
        guard Auth.auth().currentUser != nil else { return }
        
        FirestoreService.shared.checkCompletedOnboardingAndApprovedByAdmin(type: .user, userUID: Auth.auth().currentUser!.uid) { (completed, approvedByAdmin) in
            if !completed {
                //segue to agreements page
                self.performSegue(withIdentifier: "agreements", sender: nil)
                FirestoreService.shared.updateOnboardingComplete(type: .user, userUID: Auth.auth().currentUser!.uid) { (success) in
                    if success == false {
                        print("Error updating Onboarding info...")
                    }
                }
                
                self.newUser = true
            }
        }
    }
    
    func setSessionMenu() {
        if userService.shared.currentSession == nil {
            self.currentSessionLbl.text = "Not in Session"
            self.djNameLbl.text = ""
        } else {
            self.currentSessionLbl.text = "Current Session"
            self.djNameLbl.text = userService.shared.currentSession?.djName
            
            if userService.shared.currentSession != nil {
                if userService.shared.currentSession?.onlineEvent != true {
                    guard let venueCoords = userService.shared.currentSession?.venueCoord else {
                        return
                    }
                    
                    self.onlineEventCover.alpha = 0
                    
                    let location = CLLocation(latitude: venueCoords.latitude, longitude: venueCoords.longitude)
                    
                    let venueAnnotation = MKPointAnnotation()
                    venueAnnotation.title = userService.shared.currentSession?.venueName ?? ""
                    
                    venueAnnotation.coordinate = CLLocationCoordinate2D(latitude: venueCoords.latitude, longitude: venueCoords.longitude)
                    self.sessionMapView.addAnnotation(venueAnnotation)
                    
                    self.sessionMapView.centerToLocation(location)
                } else {
                    self.onlineEventCover.alpha = 1
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        getDJData()
        getData()
        
        if self.newUser == true {
            let defaults = UserDefaults.standard
            let completed = defaults.bool(forKey: DID_COMPLETE_DJ_ONBOARDING)
            if completed == true {
                introAlert()
                defaults.set(true, forKey: DID_COMPLETE_DJ_ONBOARDING)
                self.newUser = false
            }
        }
    }
    
    //MARK: GET DATA
    private func getDJData() {
        FirestoreService.shared.getFavoriteDJs(vc: self) { (djData)  in
            if djData.isEmpty == true {
                self.noRecentsLabel.alpha = 1
                self.djData = []
                self.recentDJCollection.reloadData()
                return
            }
            
            self.noRecentsLabel.alpha = 0
            self.djData = djData.sorted(by: {$0.name ?? "" < $1.name ?? ""})
            self.recentDJCollection.reloadData()
        }
    }
    
    func introAlert() {
        Alerts.shared.ok(viewController: self, title: "Welcome to cueBoom!", message: "Here, you can find upcoming online events, and some of the great DJs you've been engaging with. If you want to join a gig tap that note symbol at the top left corner!")
        return
    }
    
    private func getData() {
        FirestoreService.shared.getOnlineEvents(vc: self) { (sessions) in
            if sessions != nil {
                self.sessionData = sessions!.sorted(by: {$0.djName < $1.djName})
                self.upcomingTable.reloadData()
            }
        }
    }
    
    @IBAction func openCurrentSessionView(_ sender: Any) {
        UIView.animate(withDuration: 0.25) {
            self.currentSessionView.transform = CGAffineTransform(translationX: 0, y: -300)
            self.openCurrentSessionButton.transform = CGAffineTransform(translationX: 0, y: -300)
            self.notifsView.transform = CGAffineTransform(translationX: 0, y: -300)
        }
    }
    
    @IBAction func closeSessionView(_ sender: Any) {
        UIView.animate(withDuration: 0.25) {
            self.currentSessionView.transform = CGAffineTransform(translationX: 0, y: 0)
            self.openCurrentSessionButton.transform = CGAffineTransform(translationX: 0, y: 0)
            self.notifsView.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }
    
    @IBAction func toSessionDashboardTapped(_ sender: Any) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        toRequest()
    }
    
    @IBAction func searchTapped(_ sender: Any) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        toSearch()
    }
    
    @IBAction func menuTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "UserMain", bundle: nil)
        let newVC = storyboard.instantiateViewController(identifier: "UserMenuVC") as! UserMenuVC
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.pushViewController(newVC, animated: true)
    }
}

extension dashBoardViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.djData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "dj", for: indexPath) as! DJCollectionViewCell
        let currentDJ = self.djData[indexPath.row]
        let name = currentDJ.name
        let uid = currentDJ.uid
        let img = currentDJ.djImgUrl
        cell.setCell(djName: name, djUID: uid, profile: img)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentDJ = self.djData[indexPath.row]
        
        let storyboard = UIStoryboard(name: "UserMain", bundle: nil)
        let newVC = storyboard.instantiateViewController(withIdentifier: "DJprofile") as! djProfileUserSideViewController
        newVC.djName = currentDJ.name
        newVC.dj = currentDJ
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.pushViewController(newVC, animated: true)
    }
    
    // MARK: -- UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 70, height: 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}


extension dashBoardViewController: UITableViewDelegate, UITableViewDataSource {
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
        let session = self.sessionData[indexPath.row]
        userService.shared.currentSession = session
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        performSegue(withIdentifier: "toMain", sender: session)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

private extension MKMapView {
  func centerToLocation( _ location: CLLocation, regionRadius: CLLocationDistance = 3000) {
      let coordinateRegion = MKCoordinateRegion(
        center: location.coordinate,
        latitudinalMeters: regionRadius,
        longitudinalMeters: regionRadius)
    setRegion(coordinateRegion, animated: true)
  }
}

extension dashBoardViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        toSearch()
    }
    
}
