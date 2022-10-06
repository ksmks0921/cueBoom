//
//  DJUpdateTimeVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/10/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import FirebaseFirestore

class DJEditTimeVC: UIViewController {
    
    private var _session: Session!
    var session: Session! {
        get {
            return _session
        } set {
            _session = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Load DJSetTime nib
        let nib = Bundle.main.loadNibNamed("DJSetTimeView", owner: self, options: nil)?.first as! DJSetTimeView
        nib.frame = view.frame
        nib.delegate = self
        //Change "Add Gig" button title "Update Gig"
        //TODO: Too messy, reconfigure the nib to exclude the button. Add button on VC in storyboard
        nib.confirmBtn.changeTitleText(toString: "UPDATE TIME")
        view.addSubview(nib)
    }
    
    
    func confirmationAlert(time: String) {
        let alert = UIAlertController(title: "Confirm Time", message: "Please confirm the selected date and time: \(time)", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Change", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            
        }))
        
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            
            self.updateSession()
            
        }))
        
        
        present(alert, animated: true, completion: nil)
    }
    
    //Update the session in firestore to reflect newly changed time
    func updateSession() {
        guard let session = _session else {return}
        print(session.sessionUid)
        FirestoreService.shared.createSession(sessionUid: session.sessionUid, sessionData: session.getDataDict()) { (success) in
            //Go back to confirmation screen
            self.performSegue(withIdentifier: "backToEdit", sender: session)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let session = sender as? Session else {return}
        if let dest = segue.destination as? DJEditGigVC {
            dest.session = session
        }
    }
}

extension DJEditTimeVC: DJSetTimeDelegate {
    
    func addTimeBtnTapped(selectedDate date: Date) {
        guard _session != nil else {return}
        
        //Add time of session to _session
        _session.startTime = Timestamp(date: date)
        
        let endTime = date.addingTimeInterval(TimeInterval(43200))
        _session.endTime = Timestamp(date: endTime)
        //Present alert
        confirmationAlert(time: FormatDate.shared.getString(date))
    }
}
