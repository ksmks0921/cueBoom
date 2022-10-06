//
//  DJEditGigVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/9/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import GeoFire
class DJEditGigVC: UIViewController {
    
    private var _session: Session!
    var session: Session {
        get {
            return _session
        } set {
            _session = newValue
        }
    }
    
    var confirmGigView: DJConfirmGigView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Load the nib view
        confirmGigView = Bundle.main.loadNibNamed("DJConfirmGigView", owner: self, options: nil)?.first as! DJConfirmGigView
        
        confirmGigView.frame = view.frame
        confirmGigView.delegate = self
        
        //Change "Add Gig" button title "Update Gig"
        //TODO: Too messy, reconfigure the nib to exclude the button. Add button on VC in storyboard
       confirmGigView.confirmBtn.changeTitleText(toString: "UPDATE GIG")
        
        //Configure the nib view
        if _session != nil {
            confirmGigView.configureView(session: _session)
        }
        
        //Add nib view to view
        view.addSubview(confirmGigView)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        //Configure the nib view
        if _session != nil {
            confirmGigView.configureView(session: _session)
        }
    }
    
    @IBAction func unwindToEditGig(segue: UIStoryboardSegue) {}
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let session = sender as? Session else {return}
        
        if let destination = segue.destination as? DJEditVenueVC {
            destination.session = session
        } else if let destination = segue.destination as? DJEditTimeVC {
            destination.session = session
        }
    }
}

extension DJEditGigVC: ConfirmGigDelegate {
    func toggledOnline(online: Bool) {
        self.session.onlineEvent = online
    }
    
    func venueTapped(segue: BackSegue) {
        guard _session != nil else {return}
        performSegue(withIdentifier: "toEditVenue", sender: _session)
    }
    
    func dateTimeTapped(segue: BackSegue) {
        guard _session != nil else {return}
        performSegue(withIdentifier: "toEditTime", sender: _session)
    }
    
    func addGigTapped(eventDetails: String?) {
        guard _session != nil else {return}
        
        _session.eventInfo = eventDetails ?? nil
        
        let key = _session.sessionUid
        let location = CLLocation(latitude: _session.venueCoord.latitude, longitude: _session.venueCoord.longitude)
        
        //Add location to realtime db
        RealtimeService.shared.addActiveVenue(key: key, location: location) { success in
            guard success == true else {return}
            
            //Add session to sessions collection
            FirestoreService.shared.createSession(sessionUid: key, sessionData: self._session.getDataDict(), completion: { success in
                print(key)
                
                //Add pointer to this session in djs_public/sessions
                FirestoreService.shared.addSessionReference(sessionUid: self.session.sessionUid) { success in
                    self.navigationController?.popViewController(animated: true)
                    //                    for vc in self.navigationController!.viewControllers {
//                        if vc.isKind(of: DJGigsVC.self) {
//                            self.navigationController?.popToViewController(vc, animated: true)
//                        }
//                    }
                }
                
                
            })
        }
    }
}

