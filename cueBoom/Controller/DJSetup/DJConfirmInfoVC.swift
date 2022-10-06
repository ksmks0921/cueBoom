//
//  DJConfirmInfoVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/4/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import GeoFire
class DJConfirmInfoVC: UIViewController {
    
    enum backSegue: String {
        case time = "time"
        case venue = "venue"
    }
    
    private var _session: Session!
    var session: Session {
        get {
            return _session
        } set {
            _session = newValue
        }
    }
    

    @IBOutlet weak var venueNameLbl: UILabel!
    @IBOutlet weak var dateTimeLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if _session != nil {
            venueNameLbl.text = _session.venueName
            dateTimeLbl.text = FormatDate.shared.getString(_session!.startTime.dateValue())
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.customMakeTranslucent()
    }

    
    @IBAction func dateTimeViewTapped(_ sender: Any) {
        goBackAlert(backSegue: .time)
    }
    
    @IBAction func venueNameViewTapped(_ sender: Any) {
        goBackAlert(backSegue: .venue)
    }
    
    @IBAction func addGigBtnTapped(_ sender: Any) {
        guard _session != nil else {return}
       
        
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
                    self.performSegue(withIdentifier: "toDone", sender: nil)
                }
            })
        }
    }
    
    func goBackAlert(backSegue: backSegue) {
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
                    if vc.isKind(of: DJFindVenueVC.self) {
                        self.navigationController?.popToViewController(vc, animated: true)
                    }
                }
                break
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }


 

}
