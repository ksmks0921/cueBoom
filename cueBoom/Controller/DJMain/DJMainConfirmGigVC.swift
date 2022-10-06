//
//  DJMainConfirmGigVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/9/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import FirebaseFirestore
import GeoFire
class DJMainConfirmGigVC: UIViewController {

    var _session: Session!
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Load the nib view
        let confirmGigView = Bundle.main.loadNibNamed("DJConfirmGigView", owner: self, options: nil)?.first as! DJConfirmGigView
        confirmGigView.frame = view.frame
        confirmGigView.delegate = self
        confirmGigView.currentView = self
        
        //Configure the nib view
        if _session != nil {
            //_session.djImgUrl = 
            confirmGigView.configureView(session: _session)
        }
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:))))
        
        //Add nib view to view
        view.addSubview(confirmGigView)
    }
    
    func goBackAlert(backSegue: BackSegue) {
        let alert = UIAlertController(title: "Go Back?", message: "You will lose any unsaved information.", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)            
        }))
        
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            
            switch backSegue {
            case .time:
                self.navigationController?.popViewController(animated: true)
                break
            case .venue:
                for vc in self.navigationController!.viewControllers {
                    if vc.isKind(of: DJMainFindVenueVC.self) {
                        self.navigationController?.popToViewController(vc, animated: true)
                    }
                }
                break
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
}

extension DJMainConfirmGigVC: ConfirmGigDelegate {
    
    func toggledOnline(online: Bool) {
        self._session.onlineEvent = online
    }
    
    func venueTapped(segue: BackSegue) {
        goBackAlert(backSegue: segue)
    }
    
    func dateTimeTapped(segue: BackSegue) {
        goBackAlert(backSegue: segue)
    }
    
    func addGigTapped(eventDetails: String?) {
        if self._session.onlineEvent == true {
            if eventDetails == nil || eventDetails == "" {
                Alerts.shared.ok(viewController: self, title: "Your fans need to find you!", message: "Make sure you add event details so that your fans can find you online.")
                return
            }
        }
        
        self._session.eventInfo = eventDetails
        var sesh = self._session.getDataDict()
    
        // Converting Dates to correct data type so the compiler understands
        let startDate = sesh["startTime"] as! Timestamp
        let timeStamp = sesh["timestamp"] as! Timestamp
        let endTime = sesh["endTime"] as! Timestamp
        
        sesh.updateValue(startDate, forKey: "startTime")
        sesh.updateValue(timeStamp, forKey: "timestamp")
        sesh.updateValue(endTime, forKey: "endTime")
        
        if sesh == nil {
            return
        } else {
            let key = sesh["sessionUid"] as! String
            let location = CLLocation(latitude: _session.venueCoord.latitude, longitude: _session.venueCoord.longitude)

            RealtimeService.shared.addActiveVenue(key: key, location: location) { success in
                guard success == true else {return}
                
                CloudFunctions.shared.getTransferCapability(connectAccountID: userService.shared.connectID, vc: self) { (accountStanding) in
                
                    if accountStanding == false {
                        let storyboard = UIStoryboard(name: "DJSetup", bundle: nil)
                        let newVC = storyboard.instantiateViewController(withIdentifier: "stripeSetup") as! stripeSetupViewController
                        newVC.uid = userService.shared.uid
                        newVC.modalPresentationStyle = .fullScreen
                        self.present(newVC, animated: true)
                        return
                    }
                    
                    //Add session to sessions collection
                    FirestoreService.shared.createSession(sessionUid: key, sessionData: sesh, completion: { success in
                        print(key)
                        
                        //Add pointer to this session in djs_public/sessions
                        FirestoreService.shared.addSessionReference(sessionUid: self._session.sessionUid) { success in
                            guard self.navigationController != nil else { return }
                            for vc in self.navigationController!.viewControllers {
                                if vc.isKind(of: DJGigsVC.self) {
                                    self.navigationController?.popToViewController(vc, animated: true)
                                }
                            }
                        }
                    })
                }
            }
        }
    }
}
